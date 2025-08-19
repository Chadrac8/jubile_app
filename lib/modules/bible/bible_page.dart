import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'dart:convert';
import 'bible_service.dart';
import 'bible_model.dart';
import 'bible_search_page.dart';
import 'daily_content_page.dart';
import 'widgets/reading_plan_home_widget.dart';
import '../../services/branham_scraping_service.dart';
import 'views/thematic_passages_view.dart';
import 'views/bible_articles_list_view.dart';
import 'views/golden_nuggets_view.dart';
import '../../widgets/daily_bread_preview_widget.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({Key? key}) : super(key: key);

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> with SingleTickerProviderStateMixin {
  final BibleService _bibleService = BibleService();
  bool _isLoading = true;
  String? _selectedBook;
  int? _selectedChapter;
  String _searchQuery = '';
  List<BibleVerse> _searchResults = [];
  late TabController _tabController;
  Set<String> _favorites = {};
  Map<String, BibleHighlight> _highlights = {}; // Changed from Set to Map for colored highlights
  double _fontSize = 16.0;
  bool _isDarkMode = false;
  BibleVerse? _verseOfTheDay;
  Map<String, String> _notes = {}; // notes par clé de verset
  double _lineHeight = 1.5;
  String _fontFamily = '';
  Color? _customBgColor;
  // Ajout d'une variable pour suivre le verset sélectionné
  String? _selectedVerseKey;
  
  // Variable pour gérer la navigation depuis Notes
  bool _isNavigatingFromNotes = false;
  
  // Variables de paramètres de lecture
  bool _versePerLine = false; // Chaque verset sur une nouvelle ligne
  bool _showVerseNumbers = true; // Afficher les numéros de versets
  bool _showRedLetters = false; // Paroles de Jésus en rouge
  double _paragraphSpacing = 8.0; // Espacement entre paragraphes
  
  // Variables pour la sélection multiple
  bool _isMultiSelectMode = false; // Mode sélection multiple activé
  Set<String> _selectedVerses = {}; // Versets sélectionnés
  String? _selectionStartVerse; // Premier verset de la sélection en cours
  
  // Variables pour les statistiques de l'accueil
  int _readingStreak = 7; // Nombre de jours consécutifs de lecture
  int _readingTimeToday = 25; // Temps de lecture aujourd'hui en minutes

  // Variables pour l'affichage style YouVersion
  ScrollController _readingScrollController = ScrollController();
  bool _showNavigationButtons = true;
  String _currentFilter = 'all'; // Filtre pour l'onglet Notes
  String _notesSearchQuery = ''; // Recherche dans les notes et favoris
  late TextEditingController _notesSearchController;

  // Variables pour le scraping Branham
  BranhamQuoteModel? _branhamQuote;
  bool _isLoadingBranhamQuote = true;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _notesSearchController = TextEditingController();
    _tabController.addListener(() {
      setState(() {
      });
      // Charger automatiquement la dernière position de lecture quand on accède à l'onglet Lecture
      // SAUF si on navigue depuis l'onglet Notes
      if (_tabController.index == 1 && !_isNavigatingFromNotes) { // Index 1 = onglet Lecture
        _loadLastReadingPosition();
      }
      
      // Réinitialiser le flag après navigation
      if (_tabController.index == 1 && _isNavigatingFromNotes) {
        _isNavigatingFromNotes = false;
        // Sauvegarder la nouvelle position après navigation depuis Notes
        _saveLastReadingPosition();
      }
    });
    
    // Initialiser le ScrollController pour l'onglet lecture
    _readingScrollController.addListener(_onScrollChanged);
    
    _loadBible();
    _loadPrefs();
    _loadReadingSettings(); // Charger les paramètres de lecture
    _loadBranhamQuote(); // Charger la citation du jour de Branham
  }

  void _onScrollChanged() {
    if (_readingScrollController.position.userScrollDirection == ScrollDirection.reverse) {
      // Scroll vers le bas - cacher les boutons
      if (_showNavigationButtons) {
        setState(() {
          _showNavigationButtons = false;
        });
      }
    } else if (_readingScrollController.position.userScrollDirection == ScrollDirection.forward) {
      // Scroll vers le haut - montrer les boutons
      if (!_showNavigationButtons) {
        setState(() {
          _showNavigationButtons = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _readingScrollController.dispose();
    _tabController.dispose();
    _notesSearchController.dispose();
    super.dispose();
  }

  // Méthodes de navigation
  bool _canGoPreviousBook() {
    if (_bibleService.books.isNotEmpty && _selectedBook != null) {
      final currentIndex = _bibleService.books.indexWhere((b) => b.name == _selectedBook);
      return currentIndex > 0;
    }
    return false;
  }

  bool _canGoNextBook() {
    if (_bibleService.books.isNotEmpty && _selectedBook != null) {
      final currentIndex = _bibleService.books.indexWhere((b) => b.name == _selectedBook);
      return currentIndex < _bibleService.books.length - 1;
    }
    return false;
  }

  void _goToPreviousChapter() {
    if (_selectedChapter! > 1) {
      setState(() {
        _selectedChapter = _selectedChapter! - 1;
      });
      // Sauvegarder automatiquement la nouvelle position
      _saveLastReadingPosition();
    } else if (_canGoPreviousBook()) {
      final currentIndex = _bibleService.books.indexWhere((b) => b.name == _selectedBook);
      final previousBook = _bibleService.books[currentIndex - 1];
      setState(() {
        _selectedBook = previousBook.name;
        _selectedChapter = previousBook.chapters.length;
      });
      // Sauvegarder automatiquement la nouvelle position
      _saveLastReadingPosition();
    }
  }

  void _goToNextChapter() {
    final currentBook = _bibleService.books.firstWhere((b) => b.name == _selectedBook);
    if (_selectedChapter! < currentBook.chapters.length) {
      setState(() {
        _selectedChapter = _selectedChapter! + 1;
      });
      // Sauvegarder automatiquement la nouvelle position
      _saveLastReadingPosition();
    } else if (_canGoNextBook()) {
      final currentIndex = _bibleService.books.indexWhere((b) => b.name == _selectedBook);
      final nextBook = _bibleService.books[currentIndex + 1];
      setState(() {
        _selectedBook = nextBook.name;
        _selectedChapter = 1;
      });
      // Sauvegarder automatiquement la nouvelle position
      _saveLastReadingPosition();
    }
  }

  // Actions sur les versets
  void _showVerseActions(BibleVerse verse) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    final isHighlighted = _highlights.containsKey(verseKey);
    final isFavorite = _favorites.contains(verseKey);
    final hasNote = _notes.containsKey(verseKey);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec référence du verset
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primaryColor.withValues(alpha: 0.1), Theme.of(context).colorScheme.surfaceColor]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primaryColor.withValues(alpha: 0.2))),
              child: Row(
                children: [
                  Icon(Icons.auto_stories, color: Theme.of(context).colorScheme.primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${verse.book} ${verse.chapter}:${verse.verse}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primaryColor)),
                        Text(
                          verse.text.length > 80 
                            ? '${verse.text.substring(0, 80)}...'
                            : verse.text,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.textTertiaryColor.withValues(alpha: 0.8))),
                      ])),
                ])),
            
            SizedBox(height: 20),
            
            // Actions principales
            Row(
              children: [
                // Notes
                Expanded(
                  child: _buildActionButton(
                    icon: hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
                    label: hasNote ? 'Modifier note' : 'Ajouter note',
                    color: Theme.of(context).colorScheme.successColor,
                    onTap: () {
                      Navigator.pop(context);
                      _editNoteDialog(verse);
                    })),
                
                SizedBox(width: 12),
                
                // Copier
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.copy,
                    label: 'Copier',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _copyVerse(verse);
                    })),
              ]),
            
            SizedBox(height: 12),
            
            // Surlignage (avec options si déjà surligné)
            if (isHighlighted) ...[
              _buildHighlightOptions(verse),
              SizedBox(height: 12),
            ] else ...[
              _buildActionButton(
                icon: Icons.highlight,
                label: 'Surligner',
                color: Theme.of(context).colorScheme.warningColor,
                fullWidth: true,
                onTap: () {
                  Navigator.pop(context);
                  _showHighlightOptions(verse);
                }),
              SizedBox(height: 12),
            ],
            
            // Actions secondaires
            Row(
              children: [
                // Favoris
                Expanded(
                  child: _buildActionButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    label: isFavorite ? 'Retirer favori' : 'Ajouter favori',
                    color: Theme.of(context).colorScheme.errorColor,
                    onTap: () {
                      Navigator.pop(context);
                      _toggleFavorite(verse);
                    })),
                
                SizedBox(width: 12),
                
                // Partager
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: 'Partager',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _shareVerse(verse);
                    })),
              ]),
          ])));
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(fullWidth ? 16 : 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3))),
        child: fullWidth ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600)),
          ]) : Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          ])));
  }

  void _copyVerse(BibleVerse verse) {
    final text = '"${verse.text}"\n\n${verse.book} ${verse.chapter}:${verse.verse}';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surfaceColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Verset copié dans le presse-papiers',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ]),
        backgroundColor: Theme.of(context).colorScheme.successColor,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))));
  }

  Widget _buildHighlightOptions(BibleVerse verse) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    final currentHighlight = _highlights[verseKey];
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.warningColor.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.highlight, color: Theme.of(context).colorScheme.warningColor),
              SizedBox(width: 8),
              Text(
                'Surligné en ${HighlightConfig.colors[currentHighlight?.color]?['name'] ?? 'Jaune'}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.warningColor.withValues(alpha: 0.8))),
            ]),
          SizedBox(height: 12),
          Row(
            children: [
              // Modifier
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit,
                  label: 'Modifier',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showHighlightOptions(verse);
                  })),
              SizedBox(width: 12),
              // Supprimer
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer',
                  color: Theme.of(context).colorScheme.errorColor,
                  onTap: () {
                    Navigator.pop(context);
                    _removeHighlight(verse);
                  })),
            ]),
        ]));
  }

  void _showHighlightOptions(BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Icon(Icons.palette, color: Theme.of(context).colorScheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Choisir couleur et style',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primaryColor)),
              ]),
            
            SizedBox(height: 20),
            
            // Couleurs
            Text(
              'Couleurs',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))),
            SizedBox(height: 12),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: HighlightConfig.colors.entries.map((entry) {
                final colorName = entry.key;
                final colorData = entry.value;
                
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _addColoredHighlight(verse, colorName, 'highlight');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(colorData['color']).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(colorData['color']),
                        width: 2)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          colorData['icon'],
                          style: TextStyle(fontSize: 16)),
                        SizedBox(width: 6),
                        Text(
                          colorData['name'],
                          style: GoogleFonts.inter(
                            color: Color(colorData['textColor']),
                            fontWeight: FontWeight.w600)),
                      ])));
              }).toList()),
          ])));
  }

  void _addColoredHighlight(BibleVerse verse, String color, String style) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    
    setState(() {
      _highlights[verseKey] = BibleHighlight(
        verseKey: verseKey,
        color: color,
        style: style,
        createdAt: DateTime.now());
    });
    
    _saveHighlights();
    
    // Feedback visuel
    final colorData = HighlightConfig.colors[color]!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(colorData['icon'], style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text(
              'Verset surligné en ${colorData['name']}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ]),
        backgroundColor: Color(colorData['color']),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))));
  }

  void _removeHighlight(BibleVerse verse) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    
    setState(() {
      _highlights.remove(verseKey);
    });
    
    _saveHighlights();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surfaceColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Surlignage supprimé',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ]),
        backgroundColor: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.9),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10))));
  }

  Color _getHighlightColor(String verseKey) {
    final highlight = _highlights[verseKey];
    if (highlight == null) return Colors.yellow.withOpacity(0.3);
    
    final colorData = HighlightConfig.colors[highlight.color];
    if (colorData == null) return Colors.yellow.withOpacity(0.3);
    
    return Color(colorData['color']).withOpacity(0.3);
  }

  void _toggleHighlight(BibleVerse verse) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    setState(() {
      if (_highlights.containsKey(verseKey)) {
        _highlights.remove(verseKey);
      } else {
        _highlights[verseKey] = BibleHighlight(
          verseKey: verseKey,
          color: 'yellow', // couleur par défaut
          style: 'highlight',
          createdAt: DateTime.now());
      }
    });
    _saveHighlights();
  }

  void _toggleFavorite(BibleVerse verse) {
    final verseKey = '${verse.book}_${verse.chapter}_${verse.verse}';
    setState(() {
      if (_favorites.contains(verseKey)) {
        _favorites.remove(verseKey);
      } else {
        _favorites.add(verseKey);
      }
    });
    _saveFavorites();
  }

  void _shareVerse(BibleVerse verse) {
    // Implémentation du partage
  }

  void _shareBranhamQuote(Map<String, String> quote) {
    final text = '"${quote['text']!}"\n\n- William Marrion Branham\n${quote['reference']!}';
    Share.share(
      text,
      subject: 'Citation du jour - William Marrion Branham');
  }

  void _shareDailyBread() {
    final verseText = _branhamQuote?.dailyBread ?? _verseOfTheDay?.text ?? '';
    final verseReference = _branhamQuote?.dailyBreadReference ?? 
        (_verseOfTheDay != null ? '${_verseOfTheDay!.book} ${_verseOfTheDay!.chapter}:${_verseOfTheDay!.verse}' : '');
    
    final text = '"$verseText"\n\n$verseReference\n\nPain quotidien - branham.org';
    Share.share(
      text,
      subject: 'Pain quotidien');
  }

  void _shareScrapedBranhamQuote() {
    String quoteText = 'La foi est quelque chose que vous avez ; elle n\'est pas quelque chose que vous obtenez.';
    String reference = 'La Foi, 1957';
    
    if (_branhamQuote != null) {
      quoteText = _branhamQuote!.text;
      reference = _branhamQuote!.reference;
    }
    
    final text = '"$quoteText"\n\n- William Marrion Branham\n$reference\n\nbranham.org';
    Share.share(
      text,
      subject: 'Citation du jour - William Marrion Branham');
  }

  void _shareChapter() {
    // Implémentation du partage de chapitre
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taille de police'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                onChanged: (value) {
                  setDialogState(() {
                    _fontSize = value;
                  });
                  setState(() {
                    _fontSize = value;
                  });
                  _saveFontSize();
                }),
              Text('${_fontSize.round()}pt'),
            ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
        ]));
  }

  // Méthodes de sauvegarde
  Future<void> _saveHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final highlightsJson = _highlights.values.map((h) => json.encode(h.toJson())).toList();
    await prefs.setStringList('bible_highlights', highlightsJson);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bible_favorites', _favorites.toList());
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bible_notes', jsonEncode(_notes));
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bible_font_size', _fontSize);
  }

  // Afficher le sélecteur de livre et chapitre
  void _showBookChapterSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              // Handle pour drag
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choisir un livre et chapitre',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87))),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      splashRadius: 20),
                  ])),
              
              // Contenu scrollable
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // Tabs
                      TabBar(
                        labelColor: Theme.of(context).colorScheme.primaryColor,
                        unselectedLabelColor: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                        indicatorColor: Theme.of(context).colorScheme.primaryColor,
                        tabs: const [
                          Tab(text: 'Ancien Testament'),
                          Tab(text: 'Nouveau Testament'),
                        ]),
                      
                      // Tab content
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTestamentBooksList(scrollController, true), // Ancien Testament
                            _buildTestamentBooksList(scrollController, false), // Nouveau Testament
                          ])),
                    ]))),
            ]))));
  }

  Widget _buildTestamentBooksList(ScrollController scrollController, bool isOldTestament) {
    // Liste des livres de l'Ancien Testament (39 livres)
    final oldTestamentBooks = [
      'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
      'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
      '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques', 'Esdras',
      'Néhémie', 'Esther', 'Job', 'Psaumes', 'Proverbes',
      'Ecclésiaste', 'Cantique des cantiques', 'Ésaïe', 'Jérémie', 'Lamentations',
      'Ézéchiel', 'Daniel', 'Osée', 'Joël', 'Amos',
      'Abdias', 'Jonas', 'Michée', 'Nahum', 'Habacuc',
      'Sophonie', 'Aggée', 'Zacharie', 'Malachie'
    ];

    // Liste des livres du Nouveau Testament (27 livres)
    final newTestamentBooks = [
      'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
      'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates', 'Éphésiens',
      'Philippiens', 'Colossiens', '1 Thessaloniciens', '2 Thessaloniciens', '1 Timothée',
      '2 Timothée', 'Tite', 'Philémon', 'Hébreux', 'Jacques',
      '1 Pierre', '2 Pierre', '1 Jean', '2 Jean', '3 Jean',
      'Jude', 'Apocalypse'
    ];

    final booksToShow = isOldTestament ? oldTestamentBooks : newTestamentBooks;
    final availableBooks = _bibleService.books.where((book) => booksToShow.contains(book.name)).toList();

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: availableBooks.length,
      itemBuilder: (context, index) {
        final book = availableBooks[index];
        final isSelected = book.name == _selectedBook;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.1) : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primaryColor : Colors.transparent,
              width: 1)),
          child: ListTile(
            title: Text(
              book.name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Theme.of(context).colorScheme.primaryColor : Colors.black87)),
            subtitle: Text(
              '${book.chapters.length} chapitre${book.chapters.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))),
            trailing: isSelected 
                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primaryColor)
                : Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.textTertiaryColor),
            onTap: () => _showChapterSelector(book)));
      });
  }

  void _showChapterSelector(BibleBook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          book.name,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8),
            itemCount: book.chapters.length,
            itemBuilder: (context, index) {
              final chapterNumber = index + 1;
              final isSelected = chapterNumber == _selectedChapter;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedBook = book.name;
                    _selectedChapter = chapterNumber;
                  });
                  Navigator.pop(context); // Fermer dialog chapitre
                  Navigator.pop(context); // Fermer bottom sheet livre
                  _saveLastReadingPosition();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primaryColor : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primaryColor : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.3)!,
                      width: 1)),
                  child: Center(
                    child: Text(
                      '$chapterNumber',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Theme.of(context).colorScheme.surfaceColor : Colors.black87)))));
            })),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ]));
  }

  Future<void> _loadBible() async {
    await _bibleService.loadBible();
    _pickVerseOfTheDay();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadBranhamQuote() async {
    try {
      print('🔄 Chargement de la citation Branham...');
      final quote = await BranhamScrapingService.instance.getQuoteOfTheDay();
      setState(() {
        _branhamQuote = quote;
        _isLoadingBranhamQuote = false;
      });
      print('✅ Citation Branham chargée: ${quote?.text.substring(0, 50) ?? 'null'}...');
    } catch (e) {
      print('❌ Erreur lors du chargement de la citation Branham: $e');
      setState(() {
        _isLoadingBranhamQuote = false;
      });
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('bible_favorites')?.toSet() ?? {};
      
      // Charger les highlights avec couleurs
      final highlightsJson = prefs.getStringList('bible_highlights') ?? [];
      _highlights = {};
      for (String highlightStr in highlightsJson) {
        try {
          final highlight = BibleHighlight.fromJson(jsonDecode(highlightStr));
          _highlights[highlight.verseKey] = highlight;
        } catch (e) {
          // Ignorer les highlights mal formés
        }
      }
      
      _fontSize = prefs.getDouble('bible_font_size') ?? 16.0;
      _isDarkMode = prefs.getBool('bible_dark_mode') ?? false;
      final notesString = prefs.getString('bible_notes') ?? '{}';
      _notes = Map<String, String>.from(jsonDecode(notesString));
      _lineHeight = prefs.getDouble('bible_line_height') ?? 1.5;
      _fontFamily = prefs.getString('bible_font_family') ?? '';
      final colorValue = prefs.getInt('bible_custom_bg_color');
      _customBgColor = colorValue != null ? Color(colorValue) : null;
      
      // Charger la dernière position de lecture pour l'affichage initial
      final lastBook = prefs.getString('bible_last_book');
      final lastChapter = prefs.getInt('bible_last_chapter');
      if (lastBook != null && lastChapter != null) {
        _selectedBook = lastBook;
        _selectedChapter = lastChapter;
      }
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bible_favorites', _favorites.toList());
    
    // Sauvegarder les highlights avec couleurs
    final highlightsJson = _highlights.values.map((h) => json.encode(h.toJson())).toList();
    await prefs.setStringList('bible_highlights', highlightsJson);
    
    await prefs.setDouble('bible_font_size', _fontSize);
    await prefs.setBool('bible_dark_mode', _isDarkMode);
    await prefs.setString('bible_font_family', _fontFamily);
    await prefs.setDouble('bible_line_height', _lineHeight);
    await prefs.setString('bible_notes', jsonEncode(_notes));
    if (_customBgColor != null) {
      await prefs.setInt('bible_custom_bg_color', _customBgColor!.value);
    }
  }

  // Nouvelles méthodes pour gérer la position de lecture
  Future<void> _loadLastReadingPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBook = prefs.getString('bible_last_book');
    final lastChapter = prefs.getInt('bible_last_chapter');
    
    setState(() {
      if (lastBook != null && lastChapter != null) {
        // Charger la dernière position de lecture
        _selectedBook = lastBook;
        _selectedChapter = lastChapter;
      } else {
        // Position par défaut : Genèse 1
        _selectedBook = 'Genèse';
        _selectedChapter = 1;
      }
    });

    // Sauvegarder la nouvelle position si c'est la première fois
    if (lastBook == null || lastChapter == null) {
      await _saveLastReadingPosition();
    }
  }

  Future<void> _saveLastReadingPosition() async {
    if (_selectedBook != null && _selectedChapter != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bible_last_book', _selectedBook!);
      await prefs.setInt('bible_last_chapter', _selectedChapter!);
      await prefs.setString('bible_last_read_date', DateTime.now().toIso8601String());
    }
  }

  // Méthode pour obtenir le titre du bouton de lecture
  String _getLastReadingTitle() {
    if (_selectedBook != null && _selectedChapter != null) {
      return 'Continuer\n$_selectedBook $_selectedChapter';
    }
    return 'Commencer\nGenèse 1';
  }

  void _editNoteDialog(BibleVerse v) {
    final key = _verseKey(v);
    final controller = TextEditingController(text: _notes[key] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note pour ${v.book} ${v.chapter}:${v.verse}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Écris ta note ici...')),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                if (controller.text.trim().isEmpty) {
                  _notes.remove(key);
                } else {
                  _notes[key] = controller.text.trim();
                }
              });
              _savePrefs();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ]));
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      // Recherche avancée :
      final refReg = RegExp(r'^(\w+)\s*(\d+):(\d+)$');
      final match = refReg.firstMatch(query.trim());
      if (match != null) {
        // Recherche par référence (ex: Jean 3:16)
        final book = match.group(1)!;
        final chapter = int.tryParse(match.group(2)!);
        final verse = int.tryParse(match.group(3)!);
        if (chapter != null && verse != null) {
          final found = _bibleService.books.where((b) => b.name.toLowerCase().contains(book.toLowerCase())).toList();
          if (found.isNotEmpty) {
            final b = found.first;
            if (chapter > 0 && chapter <= b.chapters.length && verse > 0 && verse <= b.chapters[chapter-1].length) {
              _searchResults = [BibleVerse(book: b.name, chapter: chapter, verse: verse, text: b.chapters[chapter-1][verse-1])];
              return;
            }
          }
        }
      }
      // Recherche par expression exacte entre guillemets
      final exactReg = RegExp(r'^"(.+)"$');
      final exactMatch = exactReg.firstMatch(query.trim());
      if (exactMatch != null) {
        final phrase = exactMatch.group(1)!;
        _searchResults = _bibleService.search(phrase).where((v) => v.text.contains(phrase)).toList();
        return;
      }
      // Recherche par mot-clé classique
      _searchResults = _bibleService.search(query);
    });
  }

  void _pickVerseOfTheDay() {
    final allVerses = <BibleVerse>[];
    for (final book in _bibleService.books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          allVerses.add(BibleVerse(book: book.name, chapter: c + 1, verse: v + 1, text: book.chapters[c][v]));
        }
      }
    }
    if (allVerses.isNotEmpty) {
      final now = DateTime.now();
      final index = (now.year * 10000 + now.month * 100 + now.day) % allVerses.length;
      _verseOfTheDay = allVerses[index];
    }
  }

  String _verseKey(BibleVerse v) => '${v.book}_${v.chapter}_${v.verse}';

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? ThemeData.dark().copyWith(
      colorScheme: Theme.of(context).colorScheme.lightTheme.colorScheme.copyWith(brightness: Brightness.dark),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)) : Theme.of(context).colorScheme.lightTheme;
    if (_isLoading) {
      // Shimmer premium sur l’accueil Bible
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.backgroundColor, // Couleur d'arrière-plan unifiée pour la vue Membre
        body: Center(
          child: Shimmer.fromColors(
            baseColor: theme.colorScheme.surface,
            highlightColor: theme.colorScheme.primary.withOpacity(0.13),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12))),
                const SizedBox(height: 18),
                Container(
                  width: 320,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor,
                    borderRadius: BorderRadius.circular(24))),
                const SizedBox(height: 18),
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8))),
              ]))));
    }
    final books = _bibleService.books;
    return Theme(
      data: theme,
      child: Column(
        children: [
          // TabBar sans AppBar - Style identique au module Message
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryColor, // Rouge bordeaux
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primaryActive.withOpacity(0.3), // Ombre avec couleur active
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
              ]),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.backgroundColor, // Indicateur blanc cassé sur rouge bordeaux
              indicatorWeight: 3,
              labelColor: Theme.of(context).colorScheme.surfaceColor,
              unselectedLabelColor: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.7),
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
                fontSize: 14),
              tabs: const [
                Tab(icon: Icon(Icons.home, size: 20), text: 'Accueil'),
                Tab(icon: Icon(Icons.menu_book, size: 20), text: 'Lecture'),
                Tab(icon: Icon(Icons.note_alt, size: 20), text: 'Notes'),
              ])),
          // TabBarView - Style identique au module Message
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHomeTab(),
                _buildModernReadingTab(books),
                _buildNotesAndHighlightsTab(),
              ])),
        ]));
  }

  Widget _buildHomeTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05)!,
            Theme.of(context).colorScheme.surfaceColor,
          ])),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Pain quotidien professionnel - pleine largeur
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: DailyBreadPreviewWidget())),
          
          // Liste des modules bibliques
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre de section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Modules Bibliques',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.textPrimaryColor))),
                  
                  // Plans de lecture
                  const ReadingPlanHomeWidget(),
                  const SizedBox(height: 16),
                  
                  // Passages thématiques
                  _buildBibleModuleCard(
                    title: 'Passages thématiques',
                    subtitle: 'Découvrez des versets organisés par thèmes',
                    icon: Icons.topic,
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      // Navigation vers les passages thématiques
                      _navigateToThematicPassages();
                    }),
                  const SizedBox(height: 16),
                  
                  // Articles bibliques
                  _buildBibleModuleCard(
                    title: 'Articles bibliques',
                    subtitle: 'Études approfondies et commentaires',
                    icon: Icons.article,
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      // Navigation vers les articles bibliques
                      _navigateToBibleArticles();
                    }),
                  const SizedBox(height: 16),
                  
                  // Pépites d'or (Citations de William Marrion Branham)
                  _buildBibleModuleCard(
                    title: 'Pépites d\'or',
                    subtitle: 'Condensé des citations du prophète William Marrion Branham',
                    icon: Icons.diamond,
                    color: const Color(0xFFD4AF37), // Couleur or
                    onTap: () {
                      // Navigation vers les pépites d'or
                      _navigateToGoldenNuggets();
                    }),
                  const SizedBox(height: 40),
                ]))),
        ]));
  }

  // Méthode pour construire une carte de module biblique
  Widget _buildBibleModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textPrimaryColor)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                          height: 1.3)),
                    ])),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.textSecondaryColor,
                  size: 18),
              ])))));
  }

  // Méthodes de navigation
  void _navigateToThematicPassages() {
    // Navigation vers la page des passages thématiques
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThematicPassagesView()));
  }

  void _navigateToBibleArticles() {
    // Navigation vers la page des articles bibliques
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BibleArticlesListView()));
  }

  void _navigateToGoldenNuggets() {
    // Navigation vers la page des pépites d'or (Citations de William Marrion Branham)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoldenNuggetsView()));
  }

  Widget _buildModernHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryColor,
            Theme.of(context).colorScheme.primaryColor.withOpacity(0.8),
          ]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16)),
                child: const Icon(
                  Icons.auto_stories,
                  color: Theme.of(context).colorScheme.surfaceColor,
                  size: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'Continuons notre lecture',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.surfaceColor)),
                  ])),
            ]),
          
          const SizedBox(height: 20),
          
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Jour consécutif',
                  value: '${_readingStreak}',
                  color: Theme.of(context).colorScheme.warningColor)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.bookmark,
                  title: 'Favoris',
                  value: '${_favorites.length}',
                  color: Colors.amber)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  title: 'Temps de lecture',
                  value: '${_readingTimeToday}min',
                  color: Colors.blue)),
            ]),
        ]));
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.surfaceColor,
              size: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.surfaceColor)),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.8),
              fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
        ]));
  }

  Widget _buildVerseOfTheDay() {
    // Utiliser le Pain quotidien depuis le scraping Branham ou fallback sur le verset local
    final verseText = _branhamQuote?.dailyBread ?? _verseOfTheDay?.text ?? 'Chargement...';
    final verseReference = _branhamQuote?.dailyBreadReference ?? 
        (_verseOfTheDay != null ? '${_verseOfTheDay!.book} ${_verseOfTheDay!.chapter}:${_verseOfTheDay!.verse}' : '');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[50]!,
            Theme.of(context).colorScheme.warningColor.withOpacity(0.05)!,
          ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4)),
        ]),
      child: Padding(
        padding: const EdgeInsets.all(20), // Réduit de 24 à 20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Réduit de 12 à 10
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber, Theme.of(context).colorScheme.warningColor]),
                    borderRadius: BorderRadius.circular(14), // Réduit de 16 à 14
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                    ]),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 22, // Réduit de 24 à 22
                  )),
                const SizedBox(width: 14), // Réduit de 16 à 14
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pain quotidien',
                        style: GoogleFonts.poppins(
                          fontSize: 18, // Réduit de 20 à 18
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800])),
                      Text(
                        _getCurrentDate(),
                        style: GoogleFonts.inter(
                          fontSize: 13, // Réduit de 14 à 13
                          color: Colors.amber[600],
                          fontWeight: FontWeight.w500)),
                    ])),
                IconButton(
                  onPressed: () => _shareDailyBread(),
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                    foregroundColor: Colors.amber[700])),
              ]),
            
            const SizedBox(height: 16), // Réduit de 20 à 16
            
            // Quote container
            Expanded( // Utiliser Expanded au lieu d'une hauteur fixe
              child: Container(
                padding: const EdgeInsets.all(16), // Réduit de 20 à 16
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                  ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.amber[300],
                      size: 28, // Réduit de 32 à 28
                    ),
                    const SizedBox(height: 6), // Réduit de 8 à 6
                    _isLoadingBranhamQuote 
                      ? Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.amber[600],
                              strokeWidth: 2)))
                      : Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _getPreviewText(verseText, 120), // Aperçu limité à 120 caractères
                                  style: GoogleFonts.crimsonText(
                                    fontSize: _fontSize + 2,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500))),
                              if (verseText.length > 120) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _openDailyContentPage(),
                                  child: Text(
                                    'Lire plus...',
                                    style: GoogleFonts.inter(
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline))),
                              ],
                            ])),
                    const SizedBox(height: 12), // Réduit de 16 à 12
                    if (verseReference.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Réduit le padding
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            verseReference,
                            style: GoogleFonts.inter(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12, // Réduit de 13 à 12
                            )))),
                  ]))),
          ])));
  }

  Widget _buildQuoteOfTheDay() {
    // Utiliser la citation scrapée ou fallback
    String quoteText = 'Chargement de la citation...';
    String quoteReference = 'William Marrion Branham';
    
    if (!_isLoadingBranhamQuote && _branhamQuote != null) {
      quoteText = _branhamQuote!.text;
      quoteReference = _branhamQuote!.reference;
    } else if (!_isLoadingBranhamQuote) {
      // Fallback sur une citation par défaut
      quoteText = 'La foi est quelque chose que vous avez ; elle n\'est pas quelque chose que vous obtenez.';
      quoteReference = 'La Foi, 1957';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.indigo[50]!,
          ]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4)),
        ]),
      child: Padding(
        padding: const EdgeInsets.all(20), // Réduit de 24 à 20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Réduit de 12 à 10
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.indigo]),
                    borderRadius: BorderRadius.circular(14), // Réduit de 16 à 14
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                    ]),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 22, // Réduit de 24 à 22
                  )),
                const SizedBox(width: 14), // Réduit de 16 à 14
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Citation du jour',
                        style: GoogleFonts.poppins(
                          fontSize: 18, // Réduit de 20 à 18
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800])),
                      Text(
                        'William Marrion Branham',
                        style: GoogleFonts.inter(
                          fontSize: 13, // Réduit de 14 à 13
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500)),
                    ])),
                IconButton(
                  onPressed: () => _shareScrapedBranhamQuote(),
                  icon: const Icon(Icons.share),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                    foregroundColor: Colors.blue[700])),
              ]),
            
            const SizedBox(height: 16), // Réduit de 20 à 16
            
            // Quote container
            Expanded( // Utiliser Expanded au lieu d'une hauteur fixe
              child: Container(
                padding: const EdgeInsets.all(16), // Réduit de 20 à 16
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                  ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Colors.blue[300],
                      size: 28, // Réduit de 32 à 28
                    ),
                    const SizedBox(height: 6), // Réduit de 8 à 6
                    _isLoadingBranhamQuote 
                      ? Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue[600],
                              strokeWidth: 2)))
                      : Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _getPreviewText(quoteText, 120), // Aperçu limité à 120 caractères
                                  style: GoogleFonts.crimsonText(
                                    fontSize: _fontSize + 2,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500))),
                              if (quoteText.length > 120) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _openDailyContentPage(),
                                  child: Text(
                                    'Lire plus...',
                                    style: GoogleFonts.inter(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline))),
                              ],
                            ])),
                    const SizedBox(height: 12), // Réduit de 16 à 12
                    if (!_isLoadingBranhamQuote)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Réduit le padding
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            quoteReference,
                            style: GoogleFonts.inter(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12, // Réduit de 13 à 12
                            )))),
                  ]))),
          ])));
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDFDFD), // Blanc pur
            Color(0xFFF8FAFC), // Gris très clair
            Color(0xFFF1F5F9), // Slate très clair
          ],
          stops: [0.0, 0.5, 1.0]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Bordure slate subtile
          width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF475569).withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 0),
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4)),
          BoxShadow(
            color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, 1),
            spreadRadius: 0),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header professionnel
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryColor,
                      Color(0xFF764BA2),
                    ]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                  ]),
                child: const Icon(
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.surfaceColor,
                  size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Actions rapides',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Text(
                            'RAPIDE',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5))),
                      ]),
                    const SizedBox(height: 2),
                    const Text(
                      'Accès direct aux fonctionnalités principales',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1)),
                  ])),
            ]),
          
          const SizedBox(height: 24),
          
          // Actions avec design professionnel
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.play_circle_filled,
                  title: _getLastReadingTitle(),
                  color: Theme.of(context).colorScheme.primaryColor,
                  onTap: () {
                    // Charger la dernière position et naviguer vers l'onglet lecture
                    _loadLastReadingPosition().then((_) {
                      _tabController.animateTo(1); // Onglet Lecture
                    });
                  })),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.search,
                  title: 'Rechercher\nun passage',
                  color: Colors.blue,
                  onTap: () {
                    // Ouvrir la page de recherche
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BibleSearchPage(
                          bibleService: _bibleService)));
                  })),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.note,
                  title: 'Mes\nnotes',
                  color: Theme.of(context).colorScheme.successColor,
                  onTap: () {
                    // Ouvrir les notes
                    _showNotes();
                  })),
            ]),
        ]));
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceColor.withOpacity(0.9),
            const Color(0xFFF8FAFC).withOpacity(0.7),
          ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4)),
          BoxShadow(
            color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, 1)),
        ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4)),
                    ]),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 22)),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                    letterSpacing: 0.1),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              ])))));
  }

  // Méthodes utilitaires
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour !';
    if (hour < 17) return 'Bon après-midi !';
    return 'Bonsoir !';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _showFavorites() {
    // Naviguer vers l'onglet Notes et activer le filtre favoris
    _tabController.animateTo(2); // Onglet Notes
    setState(() {
      _currentFilter = 'favorites';
    });
  }

  void _showNotes() {
    // Naviguer vers l'onglet Notes et activer le filtre notes
    _tabController.animateTo(2); // Onglet Notes  
    setState(() {
      _currentFilter = 'notes';
    });
  }

  Widget _buildModernReadingTab(List<BibleBook> books) {
    if (_selectedBook == null || _selectedChapter == null) {
      return _buildReadingPlaceholder();
    }

    final book = books.firstWhere((b) => b.name == _selectedBook!);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceColor,
      body: Column(
        children: [
          // En-tête style YouVersion
          _buildYouVersionHeader(book),
          
          // Contenu de lecture
          Expanded(
            child: Stack(
              children: [
                // Texte biblique continu
                _buildContinuousText(book, _selectedChapter!),
                
                // Boutons de navigation (en bas)
                if (_showNavigationButtons)
                  _buildNavigationButtons(book),
              ])),
        ]));
  }

  Widget _buildYouVersionHeader(BibleBook book) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1),
            width: 1))),
      child: Row(
        children: [
          // Livre et chapitre - cliquable
          Expanded(
            child: GestureDetector(
              onTap: () => _showBookChapterSelector(),
              child: Row(
                children: [
                  Text(
                    book.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '$_selectedChapter',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primaryColor))),
                ]))),
          
          // Icônes à droite
          Row(
            children: [
              // Icône de recherche
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BibleSearchPage(bibleService: _bibleService)));
                  
                  // Si un résultat de recherche a été sélectionné, naviguer vers ce passage
                  if (result != null && result is Map<String, dynamic>) {
                    // Feedback haptic
                    HapticFeedback.lightImpact();
                    
                    // Afficher un snackbar de confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.surfaceColor, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Navigation vers ${result['book']} ${result['chapter']}:${result['verse']}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                          ]),
                        backgroundColor: Theme.of(context).colorScheme.successColor,
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))));
                    
                    setState(() {
                      _selectedBook = result['book'];
                      _selectedChapter = result['chapter'];
                      // Changer vers l'onglet Lecture (index 1)
                      _tabController.animateTo(1);
                    });
                    
                    // Sauvegarder la position pour la prochaine ouverture
                    await _saveLastReadingPosition();
                  }
                },
                icon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                  size: 24),
                splashRadius: 20),
              
              // Menu avec 3 points
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                  size: 24),
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      _showReadingSettings();
                      break;
                    case 'bookmark':
                      _bookmarkCurrentChapter();
                      break;
                    case 'share':
                      _shareChapter();
                      break;
                    case 'font_size':
                      _showFontSizeDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'bookmark',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_add, size: 20, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
                        const SizedBox(width: 12),
                        const Text('Marquer ce chapitre'),
                      ])),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
                        const SizedBox(width: 12),
                        const Text('Partager'),
                      ])),
                  PopupMenuItem(
                    value: 'font_size',
                    child: Row(
                      children: [
                        Icon(Icons.text_fields, size: 20, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
                        const SizedBox(width: 12),
                        const Text('Taille du texte'),
                      ])),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
                        const SizedBox(width: 12),
                        const Text('Paramètres'),
                      ])),
                ]),
            ]),
        ]));
  }

  Widget _buildContinuousText(BibleBook book, int chapter) {
    final chapterIndex = chapter - 1;
    if (chapterIndex < 0 || chapterIndex >= book.chapters.length) {
      return Center(
        child: Text(
          'Chapitre non trouvé',
          style: GoogleFonts.crimsonText(
            fontSize: 18,
            color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
            fontWeight: FontWeight.w500)));
    }

    final verses = book.chapters[chapterIndex];
    
    return SingleChildScrollView(
      controller: _readingScrollController,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
          ]),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du chapitre avec style amélioré
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primaryColor,
                      letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                    'Chapitre $chapter',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2)),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 3,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryColor,
                          Theme.of(context).colorScheme.primaryColor.withOpacity(0.3),
                        ]),
                      borderRadius: BorderRadius.circular(2))),
                ])),
            
            // Contenu des versets avec mise en valeur améliorée
            ..._versePerLine
              ? [
                  // Mode ligne par ligne avec style amélioré
                  ...verses.asMap().entries.map((entry) {
                    final verseNumber = entry.key + 1;
                    final verseText = entry.value;
                    final verseKey = '${book.name}_${chapter}_$verseNumber';
                    final isHighlighted = _highlights.containsKey(verseKey);
                    final isFavorite = _favorites.contains(verseKey);
                    final hasNote = _notes.containsKey(verseKey) && _notes[verseKey]!.isNotEmpty;
                    final isSelected = _selectedVerses.contains(verseKey);
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: _paragraphSpacing + 8),
                      child: GestureDetector(
                        onTap: () => _handleVerseTap(verseKey, verseNumber, verseText, book.name, chapter),
                        onLongPress: () => _handleVerseLongPress(verseKey, verseNumber, verseText, book.name, chapter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.08)
                                : isHighlighted
                                    ? _getHighlightColor(verseKey).withOpacity(0.1)
                                    : isFavorite
                                        ? Colors.amber.withOpacity(0.05)
                                        : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.3)
                                  : isHighlighted
                                      ? _getHighlightColor(verseKey).withOpacity(0.3)
                                      : Colors.transparent,
                              width: 1.5),
                            boxShadow: (isSelected || isHighlighted || isFavorite)
                                ? [
                                    BoxShadow(
                                      color: (isSelected ? Theme.of(context).colorScheme.primaryColor : _getHighlightColor(verseKey)).withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                                  ]
                                : null),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.crimsonText(
                                fontSize: _fontSize + 4,
                                color: Colors.black87,
                                height: _lineHeight + 0.3,
                                fontWeight: FontWeight.w400),
                              children: [
                                // Numéro du verset stylisé
                                if (_showVerseNumbers)
                                  TextSpan(
                                    text: '$verseNumber ',
                                    style: GoogleFonts.inter(
                                      fontSize: _fontSize,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.primaryColor,
                                      height: _lineHeight)),
                                // Texte du verset avec style amélioré
                                TextSpan(
                                  text: verseText,
                                  style: GoogleFonts.crimsonText(
                                    fontWeight: isFavorite ? FontWeight.w600 : FontWeight.w400,
                                    color: isFavorite ? Colors.black : Colors.black87)),
                                // Icône de note stylisée
                                if (hasNote)
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: GestureDetector(
                                      onTap: () => _showNotePopup(verseKey, _notes[verseKey]!),
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF10B981).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(0xFF10B981).withOpacity(0.3),
                                            width: 1)),
                                        child: Icon(
                                          Icons.sticky_note_2_rounded,
                                          size: 16,
                                          color: Color(0xFF10B981))))),
                              ])))));
                  }).toList(),
                ]
              : [
                  // Mode continu amélioré avec style magazine
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onLongPress: () {
                        if (!_isMultiSelectMode && verses.isNotEmpty) {
                          final firstVerseKey = '${book.name}_${chapter}_1';
                          _handleVerseLongPress(firstVerseKey, 1, verses[0], book.name, chapter);
                        }
                      },
                      child: RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          style: GoogleFonts.crimsonText(
                            fontSize: _fontSize + 6,
                            color: Colors.black87,
                            height: _lineHeight + 0.4,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3),
                          children: verses.asMap().entries.map((entry) {
                            final verseNumber = entry.key + 1;
                            final verseText = entry.value;
                            final verseKey = '${book.name}_${chapter}_$verseNumber';
                            final isHighlighted = _highlights.containsKey(verseKey);
                            final isFavorite = _favorites.contains(verseKey);
                            
                            return TextSpan(
                              children: [
                                // Numéro du verset avec style amélioré
                                if (_showVerseNumbers)
                                  TextSpan(
                                    text: '$verseNumber ',
                                    style: GoogleFonts.inter(
                                      fontSize: _fontSize + 1,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.primaryColor,
                                      height: _lineHeight)),
                                // Texte du verset avec effets visuels améliorés
                                TextSpan(
                                  text: '$verseText ',
                                  style: TextStyle(
                                    backgroundColor: isHighlighted 
                                        ? _getHighlightColor(verseKey).withOpacity(0.2)
                                        : null,
                                    decoration: _selectedVerses.contains(verseKey)
                                        ? TextDecoration.underline
                                        : null,
                                    decorationColor: _selectedVerses.contains(verseKey)
                                        ? Theme.of(context).colorScheme.primaryColor
                                        : null,
                                    decorationThickness: _selectedVerses.contains(verseKey)
                                        ? 3.0
                                        : null,
                                    fontWeight: isFavorite 
                                        ? FontWeight.w600 
                                        : FontWeight.w400,
                                    color: isFavorite ? Colors.black : Colors.black87,
                                    shadows: isFavorite ? [
                                      Shadow(
                                        color: Colors.amber.withOpacity(0.3),
                                        blurRadius: 2),
                                    ] : null),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (_isMultiSelectMode) {
                                        _handleVerseTap(verseKey, verseNumber, verseText, book.name, chapter);
                                      } else {
                                        _showVerseActions(BibleVerse(
                                          book: book.name,
                                          chapter: chapter,
                                          verse: verseNumber,
                                          text: verseText));
                                      }
                                    }),
                              ]);
                          }).toList())))),
                ],
          ])));
  }

  Widget _buildNavigationButtons(BibleBook book) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _showNavigationButtons ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton chapitre précédent
            if (_selectedChapter! > 1 || _canGoPreviousBook())
              FloatingActionButton(
                heroTag: "previous",
                onPressed: _goToPreviousChapter,
                backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                elevation: 4,
                child: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.primaryColor,
                  size: 28))
            else
              const SizedBox(width: 56), // Espace pour maintenir l'alignement
            
            // Bouton chapitre suivant  
            if (_selectedChapter! < book.chapters.length || _canGoNextBook())
              FloatingActionButton(
                heroTag: "next",
                onPressed: _goToNextChapter,
                backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                elevation: 4,
                child: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primaryColor,
                  size: 28))
            else
              const SizedBox(width: 56), // Espace pour maintenir l'alignement
          ])));
  }

  Widget _buildModernReadingHeader(List<BibleBook> books) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceColor,
            Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
          ]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        children: [
          // Titre et icône compacts
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primaryColor,
                      Theme.of(context).colorScheme.primaryColor.withOpacity(0.8),
                    ]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                  ]),
                child: const Icon(
                  Icons.menu_book,
                  color: Theme.of(context).colorScheme.surfaceColor,
                  size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lecture Biblique',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primaryColor,
                        height: 1.1)),
                    Text(
                      'Explorez les Saintes Écritures',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                        fontWeight: FontWeight.w500)),
                  ])),
              // Menu d'options compact
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 16)),
                onSelected: (value) {
                  switch (value) {
                    case 'settings':
                      _showReadingSettings();
                      break;
                    case 'history':
                      _showReadingHistory();
                      break;
                    case 'bookmark':
                      _bookmarkCurrentChapter();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primaryColor,
                          size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Paramètres de lecture',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                      ])),
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Theme.of(context).colorScheme.primaryColor,
                          size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Historique',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                      ])),
                  PopupMenuItem(
                    value: 'bookmark',
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmark_add,
                          color: Theme.of(context).colorScheme.primaryColor,
                          size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Marquer ce chapitre',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                      ])),
                ]),
            ]),
          
          const SizedBox(height: 12),
          
          // Sélecteurs compacts
          Row(
            children: [
              // Sélecteur de livre compact
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedBook != null 
                          ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.3)
                          : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1)),
                    ]),
                  child: DropdownButton<String>(
                    value: _selectedBook,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.book,
                          color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                          size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Livre',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                            fontSize: 12)),
                      ]),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primaryColor,
                      size: 18),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                    items: books.map((b) => DropdownMenuItem(
                      value: b.name,
                      child: Row(
                        children: [
                          Icon(
                            Icons.book,
                            color: Theme.of(context).colorScheme.primaryColor,
                            size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              b.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500))),
                        ]))).toList(),
                    onChanged: (v) => setState(() {
                      _selectedBook = v;
                      _selectedChapter = null;
                      // Sauvegarder la position de lecture dès qu'on change de livre
                      if (v != null) {
                        _saveLastReadingPosition();
                      }
                    }),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)))),
              
              const SizedBox(width: 10),
              
              // Sélecteur de chapitre compact
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _selectedBook != null ? Theme.of(context).colorScheme.surfaceColor : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedChapter != null 
                          ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.3)
                          : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2)),
                    boxShadow: _selectedBook != null ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1)),
                    ] : []),
                  child: DropdownButton<int>(
                    value: _selectedChapter,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: _selectedBook != null ? Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6) : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.4),
                          size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chap.',
                            style: GoogleFonts.inter(
                              color: _selectedBook != null ? Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6) : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.4),
                              fontSize: 12))),
                      ]),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: _selectedBook != null ? Theme.of(context).colorScheme.primaryColor : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.4),
                      size: 18),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                    items: _selectedBook != null
                        ? List.generate(
                            books.firstWhere((b) => b.name == _selectedBook!).chapters.length,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      '${i + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.primaryColor))),
                                ])))
                        : [],
                    onChanged: _selectedBook != null 
                        ? (v) => setState(() {
                            _selectedChapter = v;
                            // Sauvegarder la position de lecture dès qu'on change de chapitre
                            if (v != null) {
                              _saveLastReadingPosition();
                            }
                          })
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)))),
            ]),
        ]));
  }

  Widget _buildReadingPlaceholder() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    Theme.of(context).colorScheme.primaryColor.withOpacity(0.05),
                  ]),
                shape: BoxShape.circle),
              child: Icon(
                Icons.menu_book_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.7))),
            const SizedBox(height: 32),
            Text(
              _selectedBook == null
                  ? 'Choisissez un livre pour commencer'
                  : 'Sélectionnez un chapitre',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              _selectedBook == null
                  ? 'Explorez les 66 livres de la Bible et plongez dans la Parole de Dieu'
                  : 'Découvrez les versets du livre ${_selectedBook}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                height: 1.5),
              textAlign: TextAlign.center),
            const SizedBox(height: 32),
            if (_selectedBook == null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  // Suggestion de livre aléatoire
                  final suggestions = ['Jean', 'Psaumes', 'Proverbes', 'Matthieu', 'Romains'];
                  final random = suggestions[DateTime.now().millisecond % suggestions.length];
                  setState(() {
                    _selectedBook = random;
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Suggestion aléatoire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                  elevation: 0)),
            ],
          ])));
  }

  Widget _buildModernVersesList(BibleBook book, int chapter) {
    final theme = Theme.of(context);
    final verses = book.chapters[chapter - 1];
    
    if (_isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => Shimmer.fromColors(
          baseColor: theme.colorScheme.surface,
          highlightColor: theme.colorScheme.primary.withOpacity(0.13),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceColor,
              borderRadius: BorderRadius.circular(16)))));
    }
    
    return Column(
      children: [
        // En-tête du chapitre compact
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryColor.withOpacity(0.08),
                Theme.of(context).colorScheme.primaryColor.withOpacity(0.03),
              ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1))),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(
                      Icons.auto_stories,
                      color: Theme.of(context).colorScheme.primaryColor,
                      size: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${book.name} ${chapter}',
                          style: GoogleFonts.crimsonText(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primaryColor)),
                        Text(
                          '${verses.length} versets',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                            fontWeight: FontWeight.w500)),
                      ])),
                  // Navigation rapide compacte
                  Row(
                    children: [
                      if (chapter > 1)
                        IconButton(
                          onPressed: () => setState(() => _selectedChapter = chapter - 1),
                          icon: const Icon(Icons.navigate_before),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                            foregroundColor: Theme.of(context).colorScheme.primaryColor,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32)),
                          tooltip: 'Chapitre précédent'),
                      const SizedBox(width: 6),
                      if (chapter < book.chapters.length)
                        IconButton(
                          onPressed: () => setState(() => _selectedChapter = chapter + 1),
                          icon: const Icon(Icons.navigate_next),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                            foregroundColor: Theme.of(context).colorScheme.primaryColor,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(32, 32)),
                          tooltip: 'Chapitre suivant'),
                    ]),
                ]),
            ])),
        
        // Liste des versets optimisée
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: verses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final v = BibleVerse(book: book.name, chapter: chapter, verse: i + 1, text: verses[i]);
              final key = _verseKey(v);
              final isFav = _favorites.contains(key);
              final isHighlight = _highlights.containsKey(key);
              final note = _notes[key];
              
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (i * 15)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child)),
                child: Container(
                  decoration: BoxDecoration(
                    color: isHighlight
                        ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.08)
                        : Theme.of(context).colorScheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isHighlight 
                        ? Border.all(color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3), width: 1.5)
                        : Border.all(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 1)),
                    ]),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête du verset compact
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Numéro du verset compact
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                                      Theme.of(context).colorScheme.primaryColor.withOpacity(0.05),
                                    ]),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '${v.verse}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primaryColor))),
                              
                              const SizedBox(width: 12),
                              
                              // Texte du verset
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verses[i],
                                      style: _fontFamily.isNotEmpty
                                          ? GoogleFonts.getFont(
                                              _fontFamily,
                                              fontSize: _fontSize,
                                              height: _lineHeight,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))
                                          : GoogleFonts.crimsonText(
                                              fontSize: _fontSize,
                                              height: _lineHeight,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))),
                                    
                                    const SizedBox(height: 6),
                                    
                                    // Référence compacte
                                    Text(
                                      '${v.book} ${v.chapter}:${v.verse}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5),
                                        fontWeight: FontWeight.w500)),
                                  ])),
                              
                              // Indicateurs compacts
                              Column(
                                children: [
                                  if (isFav)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        shape: BoxShape.circle),
                                      child: Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber[700])),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle),
                                      child: Icon(
                                        Icons.sticky_note_2,
                                        size: 12,
                                        color: Colors.blue[700])),
                                  ],
                                ]),
                            ]),
                          
                          // Note si présente (compacte)
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2))),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.sticky_note_2,
                                    color: Colors.blue[700],
                                    size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      note,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontStyle: FontStyle.italic))),
                                ])),
                          ],
                          
                          // Actions compactes (quand le verset est sélectionné)
                          if (_selectedVerseKey == key) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildVerseAction(
                                    icon: isFav ? Icons.star : Icons.star_border,
                                    label: isFav ? 'Favori' : 'Favoris',
                                    color: Colors.amber[700]!,
                                    isActive: isFav,
                                    onTap: () => _toggleFavorite(v)),
                                  _buildVerseAction(
                                    icon: isHighlight ? Icons.highlight_off : Icons.highlight,
                                    label: isHighlight ? 'Surligné' : 'Surligner',
                                    color: Theme.of(context).colorScheme.primaryColor,
                                    isActive: isHighlight,
                                    onTap: () => _toggleHighlight(v)),
                                  _buildVerseAction(
                                    icon: Icons.sticky_note_2,
                                    label: note != null && note.isNotEmpty ? 'Éditer' : 'Note',
                                    color: Colors.blue[700]!,
                                    isActive: note != null && note.isNotEmpty,
                                    onTap: () => _editNoteDialog(v)),
                                  _buildVerseAction(
                                    icon: Icons.share,
                                    label: 'Partager',
                                    color: Theme.of(context).colorScheme.successColor.withOpacity(0.7)!,
                                    isActive: false,
                                    onTap: () => _shareVerse(v)),
                                ])),
                          ],
                        ])))));
            })),
      ]);
  }

  Widget _buildVerseAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withOpacity(0.3) : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
              size: 16),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isActive ? color : Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
          ])));
  }

  // Méthodes d'actions supplémentaires
  void _showReadingSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                          child: Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.primaryColor,
                            size: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paramètres de lecture',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937))),
                              Text(
                                'Personnalisez votre expérience de lecture',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
                            ])),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
                      ]),
                    
                    const SizedBox(height: 24),
                    
                    // Contenu des paramètres
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Mise en page
                            _buildSettingsSection(
                              'Mise en page',
                              Icons.view_agenda,
                              [
                                _buildSwitchSetting(
                                  'Chaque verset sur une nouvelle ligne',
                                  'Afficher chaque verset sur sa propre ligne',
                                  _versePerLine,
                                  (value) {
                                    setDialogState(() {
                                      _versePerLine = value;
                                    });
                                    setState(() {
                                      _versePerLine = value;
                                    });
                                    _saveReadingSettings();
                                  }),
                                _buildSwitchSetting(
                                  'Afficher les numéros de versets',
                                  'Masquer/afficher les numéros devant chaque verset',
                                  _showVerseNumbers,
                                  (value) {
                                    setDialogState(() {
                                      _showVerseNumbers = value;
                                    });
                                    setState(() {
                                      _showVerseNumbers = value;
                                    });
                                    _saveReadingSettings();
                                  }),
                              ]),
                            
                            const SizedBox(height: 24),
                            
                            // Section Typographie
                            _buildSettingsSection(
                              'Typographie',
                              Icons.text_fields,
                              [
                                _buildSliderSetting(
                                  'Taille du texte',
                                  _fontSize,
                                  12.0,
                                  24.0,
                                  (value) {
                                    setDialogState(() {
                                      _fontSize = value;
                                    });
                                    setState(() {
                                      _fontSize = value;
                                    });
                                    _saveReadingSettings();
                                  }),
                                _buildSliderSetting(
                                  'Hauteur de ligne',
                                  _lineHeight,
                                  1.0,
                                  2.0,
                                  (value) {
                                    setDialogState(() {
                                      _lineHeight = value;
                                    });
                                    setState(() {
                                      _lineHeight = value;
                                    });
                                    _saveReadingSettings();
                                  }),
                                if (_versePerLine)
                                  _buildSliderSetting(
                                    'Espacement entre versets',
                                    _paragraphSpacing,
                                    4.0,
                                    20.0,
                                    (value) {
                                      setDialogState(() {
                                        _paragraphSpacing = value;
                                      });
                                      setState(() {
                                        _paragraphSpacing = value;
                                      });
                                      _saveReadingSettings();
                                    }),
                              ]),
                            
                            const SizedBox(height: 24),
                            
                            // Section Apparence
                            _buildSettingsSection(
                              'Apparence',
                              Icons.palette,
                              [
                                _buildSwitchSetting(
                                  'Mode sombre',
                                  'Activer le thème sombre pour la lecture',
                                  _isDarkMode,
                                  (value) {
                                    setDialogState(() {
                                      _isDarkMode = value;
                                    });
                                    setState(() {
                                      _isDarkMode = value;
                                    });
                                    _saveReadingSettings();
                                  }),
                                _buildSwitchSetting(
                                  'Paroles de Jésus en rouge',
                                  'Afficher les paroles de Jésus en rouge',
                                  _showRedLetters,
                                  (value) {
                                    setDialogState(() {
                                      _showRedLetters = value;
                                    });
                                    setState(() {
                                      _showRedLetters = value;
                                    });
                                    _saveReadingSettings();
                                  }),
                              ]),
                          ]))),
                    
                    const SizedBox(height: 20),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              _resetReadingSettings();
                              Navigator.of(context).pop();
                            },
                            child: Text('Réinitialiser'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 12)))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primaryColor,
                              foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                            child: Text('Fermer'))),
                      ]),
                  ])));
          });
      });
  }

  void _showReadingHistory() {
    // Implémenter l'historique de lecture
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).colorScheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Historique de lecture',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.textPrimaryColor)),
              ]),
            SizedBox(height: 20),
            _buildHistoryItem('Genèse 1', 'Aujourd\'hui 14:30'),
            _buildHistoryItem('Matthieu 5', 'Hier 19:45'),
            _buildHistoryItem('Psaumes 23', 'Il y a 2 jours'),
            _buildHistoryItem('Jean 3', 'Il y a 3 jours'),
            _buildHistoryItem('Romains 8', 'Il y a 5 jours'),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer'))),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Effacer l'historique
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Historique effacé')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorColor.withOpacity(0.1),
                      foregroundColor: Theme.of(context).colorScheme.errorColor.withOpacity(0.7)),
                    child: Text('Effacer'))),
              ]),
          ])));
  }

  Widget _buildHistoryItem(String chapter, String time) {
    return ListTile(
      leading: Icon(Icons.book, color: Theme.of(context).colorScheme.primaryColor),
      title: Text(
        chapter,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.textPrimaryColor)),
      subtitle: Text(
        time,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Theme.of(context).colorScheme.textSecondaryColor)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        // Naviguer vers ce chapitre
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation vers $chapter')));
      });
  }

  // Méthodes helper pour les paramètres
  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
          ]),
        const SizedBox(height: 12),
        ...children,
      ]);
  }

  Widget _buildSwitchSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2)!)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
              ])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primaryColor),
        ]));
  }

  Widget _buildSliderSetting(String title, double value, double min, double max, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2)!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151))),
              Text(
                '${value.toStringAsFixed(1)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primaryColor)),
            ]),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primaryColor,
              inactiveTrackColor: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.3),
              thumbColor: Theme.of(context).colorScheme.primaryColor,
              overlayColor: Theme.of(context).colorScheme.primaryColor.withOpacity(0.2),
              trackHeight: 4),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) * 10).round(),
              onChanged: onChanged)),
        ]));
  }

  Future<void> _saveReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('versePerLine', _versePerLine);
    await prefs.setBool('showVerseNumbers', _showVerseNumbers);
    await prefs.setBool('showRedLetters', _showRedLetters);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setDouble('lineHeight', _lineHeight);
    await prefs.setDouble('paragraphSpacing', _paragraphSpacing);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> _loadReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _versePerLine = prefs.getBool('versePerLine') ?? false;
      _showVerseNumbers = prefs.getBool('showVerseNumbers') ?? true;
      _showRedLetters = prefs.getBool('showRedLetters') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 16.0;
      _lineHeight = prefs.getDouble('lineHeight') ?? 1.5;
      _paragraphSpacing = prefs.getDouble('paragraphSpacing') ?? 8.0;
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _resetReadingSettings() {
    setState(() {
      _versePerLine = false;
      _showVerseNumbers = true;
      _showRedLetters = false;
      _fontSize = 16.0;
      _lineHeight = 1.5;
      _paragraphSpacing = 8.0;
      _isDarkMode = false;
    });
    _saveReadingSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres réinitialisés'),
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _bookmarkCurrentChapter() async {
    if (_selectedBook != null && _selectedChapter != null) {
      // Implémenter le marque-page de chapitre
      final prefs = await SharedPreferences.getInstance();
      List<String> bookmarks = prefs.getStringList('bible_bookmarks') ?? [];
      String bookmark = '$_selectedBook $_selectedChapter';
      
      if (bookmarks.contains(bookmark)) {
        bookmarks.remove(bookmark);
        await prefs.setStringList('bible_bookmarks', bookmarks);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marque-page supprimé pour $_selectedBook $_selectedChapter'),
            backgroundColor: Theme.of(context).colorScheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      } else {
        bookmarks.insert(0, bookmark); // Ajouter au début
        if (bookmarks.length > 10) bookmarks = bookmarks.take(10).toList(); // Limiter à 10
        await prefs.setStringList('bible_bookmarks', bookmarks);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chapitre $_selectedBook $_selectedChapter marqué'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: _showBookmarks)));
      }
    }
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => FutureBuilder<List<String>>(
        future: _getBookmarks(),
        builder: (context, snapshot) {
          final bookmarks = snapshot.data ?? [];
          return Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Mes marque-pages',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.textPrimaryColor)),
                  ]),
                SizedBox(height: 20),
                if (bookmarks.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.bookmark_border, size: 48, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.4)),
                        SizedBox(height: 12),
                        Text(
                          'Aucun marque-page',
                          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
                      ]))
                else
                  ...bookmarks.map((bookmark) => 
                    ListTile(
                      leading: Icon(Icons.bookmark, color: Theme.of(context).colorScheme.primaryColor),
                      title: Text(
                        bookmark,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.textPrimaryColor)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.errorColor.withOpacity(0.4)),
                        onPressed: () async {
                          await _removeBookmark(bookmark);
                          Navigator.pop(context);
                        }),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToBookmark(bookmark);
                      })).toList(),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer'))),
              ]));
        }));
  }

  Future<List<String>> _getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('bible_bookmarks') ?? [];
  }

  Future<void> _removeBookmark(String bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('bible_bookmarks') ?? [];
    bookmarks.remove(bookmark);
    await prefs.setStringList('bible_bookmarks', bookmarks);
  }

  void _navigateToBookmark(String bookmark) {
    // Analyser le marque-page (ex: "Genèse 1")
    final parts = bookmark.split(' ');
    if (parts.length >= 2) {
      final book = parts[0];
      final chapter = int.tryParse(parts[1]);
      if (chapter != null) {
        setState(() {
          _selectedBook = book;
          _selectedChapter = chapter;
        });
        _tabController.animateTo(1); // Aller à l'onglet lecture
        _saveLastReadingPosition();
      }
    }
  }

  Widget _buildSearchTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05)!,
            Theme.of(context).colorScheme.surfaceColor,
          ])),
      child: Column(
        children: [
          // En-tête moderne avec champ de recherche
          _buildModernSearchHeader(),
          
          // Contenu principal
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildSearchEmptyState()
                : _buildModernSearchResults()),
        ]));
  }

  Widget _buildModernSearchHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4)),
        ]),
      child: Column(
        children: [
          // En-tête avec titre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[600]!,
                  Colors.blue[700]!,
                ]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherche Biblique',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.surfaceColor)),
                      Text(
                        'Explorez les Écritures',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.9),
                          fontWeight: FontWeight.w500)),
                    ])),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.surfaceColor,
                        fontWeight: FontWeight.w600))),
              ])),
          
          // Champ de recherche et filtres
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Champ de recherche principal
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2))),
                  child: TextField(
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un mot, "expression" ou référence (ex: Jean 3:16)',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5)),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                          Icons.search,
                          color: Colors.blue[600],
                          size: 20)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchResults.clear();
                                });
                              },
                              icon: const Icon(Icons.clear),
                              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5))
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20)),
                    onChanged: (query) {
                      _onSearch(query);
                      setState(() {});
                    })),
                
                const SizedBox(height: 16),
                
                // Filtres de recherche
                _buildSearchFilters(),
                
                // Suggestions de recherche
                if (_searchQuery.isEmpty)
                  _buildSearchSuggestions(),
              ])),
        ]));
  }

  Widget _buildSearchFilters() {
    return StatefulBuilder(
      builder: (context, setStateSB) {
        String? _selectedBookFilter;
        
        return Row(
          children: [
            // Filtre par livre
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2))),
                child: DropdownButton<String>(
                  value: _selectedBookFilter,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.book,
                        color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                        size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tous les livres',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500)),
                    ]),
                  underline: const SizedBox(),
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6)),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Row(
                        children: [
                          const Icon(Icons.all_inclusive, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tous les livres',
                            style: GoogleFonts.inter(fontSize: 14)),
                        ])),
                    ..._bibleService.books.map((book) => DropdownMenuItem<String>(
                      value: book.name,
                      child: Text(
                        book.name,
                        style: GoogleFonts.inter(fontSize: 14)))).toList(),
                  ],
                  onChanged: (value) {
                    setStateSB(() {
                      _selectedBookFilter = (value != null && value.isNotEmpty) ? value : null;
                    });
                  }))),
            
            const SizedBox(width: 12),
            
            // Bouton de recherche avancée
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[500]!, Colors.blue[600]!]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
                ]),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showAdvancedSearchDialog(),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune,
                          color: Theme.of(context).colorScheme.surfaceColor,
                          size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Avancé',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.surfaceColor,
                            fontWeight: FontWeight.w600)),
                      ]))))),
          ]);
      });
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      {'text': 'amour', 'icon': Icons.favorite, 'color': Theme.of(context).colorScheme.errorColor},
      {'text': 'paix', 'icon': Icons.spa, 'color': Theme.of(context).colorScheme.successColor},
      {'text': 'sagesse', 'icon': Icons.psychology, 'color': Colors.purple},
      {'text': 'espoir', 'icon': Icons.star, 'color': Colors.amber},
      {'text': 'Jean 3:16', 'icon': Icons.auto_stories, 'color': Colors.blue},
      {'text': 'Psaume 23', 'icon': Icons.music_note, 'color': Theme.of(context).colorScheme.warningColor},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Suggestions de recherche',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) => InkWell(
            onTap: () => _onSearch(suggestion['text'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (suggestion['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (suggestion['color'] as Color).withOpacity(0.3))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    suggestion['icon'] as IconData,
                    size: 16,
                    color: suggestion['color'] as Color),
                  const SizedBox(width: 6),
                  Text(
                    suggestion['text'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: suggestion['color'] as Color)),
                ])))).toList()),
      ]);
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle),
            child: Icon(
              Icons.search,
              size: 64,
              color: Colors.blue[300])),
          const SizedBox(height: 24),
          Text(
            'Commencez votre recherche',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Tapez un mot, une expression ou une référence\npour explorer les Écritures',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5),
              height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildQuickSearchCards(),
        ]));
  }

  Widget _buildQuickSearchCards() {
    final quickSearches = [
      {
        'title': 'Versets célèbres',
        'description': 'Jean 3:16, Psaume 23:1',
        'icon': Icons.star,
        'color': Colors.amber,
        'searches': ['Jean 3:16', 'Psaume 23:1', 'Matthieu 5:3-12'],
      },
      {
        'title': 'Thèmes spirituels',
        'description': 'Amour, paix, espoir',
        'icon': Icons.favorite,
        'color': Theme.of(context).colorScheme.errorColor,
        'searches': ['amour', 'paix', 'espoir', 'foi'],
      },
      {
        'title': 'Sagesse',
        'description': 'Proverbes et conseils',
        'icon': Icons.psychology,
        'color': Colors.purple,
        'searches': ['sagesse', 'conseil', 'prudence'],
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: quickSearches.map((search) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            onTap: () {
              final searches = search['searches'] as List<String>;
              _onSearch(searches.first);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (search['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (search['color'] as Color).withOpacity(0.2))),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: search['color'] as Color,
                      borderRadius: BorderRadius.circular(16)),
                    child: Icon(
                      search['icon'] as IconData,
                      color: Theme.of(context).colorScheme.surfaceColor,
                      size: 24)),
                  const SizedBox(height: 12),
                  Text(
                    search['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    search['description'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5),
                      height: 1.3),
                    textAlign: TextAlign.center),
                ])))))).toList());
  }

  Widget _buildModernSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // En-tête des résultats
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.successColor.withOpacity(0.05)!,
                  Colors.blue[50]!,
                ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.successColor.withOpacity(0.2))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.successColor,
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''} trouvé${_searchResults.length > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.successColor.withOpacity(0.7))),
                      Text(
                        'Pour la recherche: "$_searchQuery"',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6),
                          fontStyle: FontStyle.italic)),
                    ])),
              ]))),

        // Liste des résultats
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final verse = _searchResults[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildModernVerseCard(verse, index));
              },
              childCount: _searchResults.length))),

        // Espacement final
        const SliverToBoxAdapter(
          child: SizedBox(height: 20)),
      ]);
  }

  Widget _buildModernVerseCard(BibleVerse verse, int index) {
    final key = _verseKey(verse);
    final isFav = _favorites.contains(key);
    final isHighlight = _highlights.containsKey(key);
    final note = _notes[key];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child)),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlight
              ? Theme.of(context).colorScheme.primaryColor.withOpacity(0.08)
              : Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: isHighlight 
              ? Border.all(color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.3), width: 2)
              : Border.all(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
          ]),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du verset
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numéro du verset
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[500]!]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                        ]),
                      child: Text(
                        '${verse.verse}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.surfaceColor))),
                    
                    const SizedBox(width: 16),
                    
                    // Texte du verset
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verse.text,
                            style: _fontFamily.isNotEmpty
                                ? GoogleFonts.getFont(
                                    _fontFamily,
                                    fontSize: _fontSize,
                                    height: _lineHeight,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))
                                : GoogleFonts.crimsonText(
                                    fontSize: _fontSize + 2,
                                    height: _lineHeight,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))),
                          
                          const SizedBox(height: 12),
                          
                          // Référence avec badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '${verse.book} ${verse.chapter}:${verse.verse}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600))),
                        ])),
                    
                    // Indicateurs
                    Column(
                      children: [
                        if (isFav)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              shape: BoxShape.circle),
                            child: Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[700])),
                        if (note != null && note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.successColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 16,
                              color: Theme.of(context).colorScheme.successColor.withOpacity(0.7))),
                        ],
                      ]),
                  ]),
                
                // Note si présente
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.successColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.successColor.withOpacity(0.2))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          color: Theme.of(context).colorScheme.successColor.withOpacity(0.7),
                          size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            note,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.successColor.withOpacity(0.7),
                              fontStyle: FontStyle.italic))),
                      ])),
                ],
                
                // Actions (quand le verset est sélectionné)
                if (_selectedVerseKey == key) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVerseAction(
                          icon: isFav ? Icons.star : Icons.star_border,
                          label: isFav ? 'Favori' : 'Favoris',
                          color: Colors.amber[700]!,
                          isActive: isFav,
                          onTap: () => _toggleFavorite(verse)),
                        _buildVerseAction(
                          icon: isHighlight ? Icons.highlight_off : Icons.highlight,
                          label: isHighlight ? 'Surligné' : 'Surligner',
                          color: Theme.of(context).colorScheme.primaryColor,
                          isActive: isHighlight,
                          onTap: () => _toggleHighlight(verse)),
                        _buildVerseAction(
                          icon: Icons.sticky_note_2,
                          label: note != null && note.isNotEmpty ? 'Éditer' : 'Note',
                          color: Theme.of(context).colorScheme.successColor.withOpacity(0.7)!,
                          isActive: note != null && note.isNotEmpty,
                          onTap: () => _editNoteDialog(verse)),
                        _buildVerseAction(
                          icon: Icons.share,
                          label: 'Partager',
                          color: Colors.blue[700]!,
                          isActive: false,
                          onTap: () => _shareVerse(verse)),
                      ])),
                ],
              ])))));
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.warningColor.withOpacity(0.1),
              shape: BoxShape.circle),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.warningColor.withOpacity(0.3))),
          const SizedBox(height: 24),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés\nou vérifiez l\'orthographe',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5),
              height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchResults.clear();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvelle recherche'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Theme.of(context).colorScheme.surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)))),
        ]));
  }

  void _showAdvancedSearchDialog() {
    // TODO: Implémenter la recherche avancée
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recherche avancée (bientôt disponible)'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  Widget _buildFavoritesTab() {
    // Récupération des versets favoris
    final favVerses = <BibleVerse>[];
    for (final book in _bibleService.books) {
      for (int c = 0; c < book.chapters.length; c++) {
        for (int v = 0; v < book.chapters[c].length; v++) {
          final verse = BibleVerse(
            book: book.name, 
            chapter: c + 1, 
            verse: v + 1, 
            text: book.chapters[c][v]
          );
          if (_favorites.contains(_verseKey(verse))) {
            favVerses.add(verse);
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber[50]!,
            Theme.of(context).colorScheme.surfaceColor,
          ])),
      child: Column(
        children: [
          // En-tête moderne
          _buildModernFavoritesHeader(favVerses.length),
          
          // Contenu principal
          Expanded(
            child: favVerses.isEmpty
                ? _buildFavoritesEmptyState()
                : _buildModernFavoritesList(favVerses)),
        ]));
  }

  Widget _buildModernFavoritesHeader(int favoritesCount) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber[600]!,
            Theme.of(context).colorScheme.warningColor.withOpacity(0.6)!,
          ]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8)),
        ]),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 28)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes Favoris',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.surfaceColor)),
                      Text(
                        favoritesCount > 0 
                            ? '$favoritesCount verset${favoritesCount > 1 ? 's' : ''} précieux'
                            : 'Collection de versets inspirants',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.9),
                          fontWeight: FontWeight.w500)),
                    ])),
                if (favoritesCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '$favoritesCount',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.surfaceColor,
                        fontWeight: FontWeight.bold))),
              ]),
            
            if (favoritesCount > 0) ...[
              const SizedBox(height: 20),
              
              // Actions rapides
              Row(
                children: [
                  Expanded(
                    child: _buildFavoriteActionButton(
                      icon: Icons.share,
                      label: 'Partager tout',
                      onTap: () => _shareAllFavorites(favoritesCount))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFavoriteActionButton(
                      icon: Icons.download,
                      label: 'Exporter',
                      onTap: () => _exportFavorites())),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFavoriteActionButton(
                      icon: Icons.sort,
                      label: 'Trier',
                      onTap: () => _showSortOptions())),
                ]),
            ],
          ])));
  }

  Widget _buildFavoriteActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.2))),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.surfaceColor,
              size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context).colorScheme.surfaceColor.withOpacity(0.9),
                fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          ])));
  }

  Widget _buildFavoritesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[100]!, Theme.of(context).colorScheme.warningColor.withOpacity(0.1)!]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4)),
              ]),
            child: Icon(
              Icons.star_border,
              size: 64,
              color: Colors.amber[600])),
          const SizedBox(height: 32),
          Text(
            'Aucun favori pour le moment',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7))),
          const SizedBox(height: 12),
          Text(
            'Commencez à créer votre collection\nde versets inspirants',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5),
              height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildDiscoveryCards(),
        ]));
  }

  Widget _buildDiscoveryCards() {
    final discoveries = [
      {
        'title': 'Explorer la Bible',
        'description': 'Découvrez des versets\ninspirantes',
        'icon': Icons.explore,
        'color': Colors.blue,
        'onTap': () => _tabController.animateTo(1),
      },
      {
        'title': 'Rechercher',
        'description': 'Trouvez des passages\npar thème',
        'icon': Icons.search,
        'color': Theme.of(context).colorScheme.successColor,
        'onTap': () => _tabController.animateTo(2),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: discoveries.map((discovery) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: InkWell(
            onTap: discovery['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (discovery['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (discovery['color'] as Color).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: (discovery['color'] as Color).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
                ]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: discovery['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (discovery['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                      ]),
                    child: Icon(
                      discovery['icon'] as IconData,
                      color: Theme.of(context).colorScheme.surfaceColor,
                      size: 28)),
                  const SizedBox(height: 16),
                  Text(
                    discovery['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.7)),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    discovery['description'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5),
                      height: 1.3),
                    textAlign: TextAlign.center),
                ])))))).toList());
  }

  Widget _buildModernFavoritesList(List<BibleVerse> favVerses) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // En-tête de la liste avec statistiques
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[50]!, Theme.of(context).colorScheme.warningColor.withOpacity(0.05)!]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withOpacity(0.2))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Theme.of(context).colorScheme.surfaceColor,
                    size: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection personnelle',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700])),
                      Text(
                        'Vos versets précieux, toujours à portée de main',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.amber[600])),
                    ])),
              ]))),

        // Liste des favoris
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final verse = favVerses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildModernFavoriteCard(verse, index));
              },
              childCount: favVerses.length))),

        // Espacement final
        const SliverToBoxAdapter(
          child: SizedBox(height: 20)),
      ]);
  }

  Widget _buildModernFavoriteCard(BibleVerse verse, int index) {
    final key = _verseKey(verse);
    final isHighlight = _highlights.containsKey(key);
    final note = _notes[key];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surfaceColor,
              Colors.amber[25]!,
            ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4)),
          ]),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedVerseKey = (_selectedVerseKey == key) ? null : key;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec étoile dorée
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge favori doré
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Theme.of(context).colorScheme.warningColor]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                        ]),
                      child: const Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.surfaceColor,
                        size: 20)),
                    
                    const SizedBox(width: 16),
                    
                    // Numéro du verset
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${verse.verse}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700]))),
                    
                    const Spacer(),
                    
                    // Indicateurs
                    Column(
                      children: [
                        if (isHighlight)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                            child: Icon(
                              Icons.highlight,
                              size: 16,
                              color: Theme.of(context).colorScheme.primaryColor)),
                        if (note != null && note.isNotEmpty) ...[
                          if (isHighlight) const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.successColor.withOpacity(0.1),
                              shape: BoxShape.circle),
                            child: Icon(
                              Icons.sticky_note_2,
                              size: 16,
                              color: Theme.of(context).colorScheme.successColor.withOpacity(0.7))),
                        ],
                      ]),
                  ]),
                
                const SizedBox(height: 16),
                
                // Texte du verset avec style élégant
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.1))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône de citation
                      Icon(
                        Icons.format_quote,
                        color: Colors.amber[300],
                        size: 24),
                      const SizedBox(height: 8),
                      Text(
                        verse.text,
                        style: _fontFamily.isNotEmpty
                            ? GoogleFonts.getFont(
                                _fontFamily,
                                fontSize: _fontSize + 2,
                                height: _lineHeight,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8))
                            : GoogleFonts.crimsonText(
                                fontSize: _fontSize + 4,
                                height: _lineHeight,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.8),
                                fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      // Référence avec style
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber[100]!, Theme.of(context).colorScheme.warningColor.withOpacity(0.1)!]),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            '${verse.book} ${verse.chapter}:${verse.verse}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w600)))),
                    ])),
                
                // Note si présente
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.successColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.successColor.withOpacity(0.2))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2,
                          color: Theme.of(context).colorScheme.successColor.withOpacity(0.7),
                          size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ma note personnelle',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.successColor.withOpacity(0.7))),
                              const SizedBox(height: 4),
                              Text(
                                note,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.successColor.withOpacity(0.6),
                                  fontStyle: FontStyle.italic)),
                            ])),
                      ])),
                ],
                
                // Actions (quand le verset est sélectionné)
                if (_selectedVerseKey == key) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[50]!, Theme.of(context).colorScheme.warningColor.withOpacity(0.05)!]),
                      borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildVerseAction(
                          icon: Icons.star,
                          label: 'Retirer',
                          color: Theme.of(context).colorScheme.errorColor.withOpacity(0.6)!,
                          isActive: true,
                          onTap: () => _toggleFavorite(verse)),
                        _buildVerseAction(
                          icon: isHighlight ? Icons.highlight_off : Icons.highlight,
                          label: isHighlight ? 'Surligné' : 'Surligner',
                          color: Theme.of(context).colorScheme.primaryColor,
                          isActive: isHighlight,
                          onTap: () => _toggleHighlight(verse)),
                        _buildVerseAction(
                          icon: Icons.sticky_note_2,
                          label: note != null && note.isNotEmpty ? 'Éditer' : 'Note',
                          color: Theme.of(context).colorScheme.successColor.withOpacity(0.7)!,
                          isActive: note != null && note.isNotEmpty,
                          onTap: () => _editNoteDialog(verse)),
                        _buildVerseAction(
                          icon: Icons.share,
                          label: 'Partager',
                          color: Colors.blue[700]!,
                          isActive: false,
                          onTap: () => _shareVerse(verse)),
                      ])),
                ],
              ])))));
  }

  // Méthodes utilitaires pour les favoris
  void _shareAllFavorites(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de $count verset${count > 1 ? 's' : ''} favori${count > 1 ? 's' : ''}'),
        backgroundColor: Colors.amber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _exportFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export des favoris (bientôt disponible)'),
        backgroundColor: Theme.of(context).colorScheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(
              'Options de tri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Par ordre alphabétique'),
              onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Par date d\'ajout'),
              onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Par livre biblique'),
              onTap: () => Navigator.pop(context)),
          ])));
  }

  Widget _buildNotesAndHighlightsTab() {
    final totalNotes = _notes.values.where((note) => note.isNotEmpty).length;
    final totalHighlights = _highlights.length;
    final totalFavorites = _favorites.length;

    return Container(
      color: Color(0xFFFAFAFA),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // En-tête compact et professionnel
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
                ]),
              child: Column(
                children: [
                  // Titre et statistiques en une ligne
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(
                          Icons.auto_stories_outlined, 
                          color: Theme.of(context).colorScheme.surfaceColor, 
                          size: 22
                        )),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes & Surlignages',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A))),
                            Text(
                              '$totalNotes notes • $totalHighlights surlignés',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)),
                          ])),
                    ]),
                  
                  const SizedBox(height: 16),
                  
                  // Barre de recherche simple sans icône
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _notesSearchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher dans vos notes et surlignages...',
                            hintStyle: GoogleFonts.inter(
                              color: Color(0xFF94A3B8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 14
                            )),
                          style: GoogleFonts.inter(
                            fontSize: 15, 
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w500),
                          onChanged: (value) {
                            setState(() {
                              _notesSearchQuery = value.toLowerCase().trim();
                            });
                          })),
                      if (_notesSearchQuery.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _notesSearchController.clear();
                                _notesSearchQuery = '';
                              });
                            },
                            iconSize: 20,
                            padding: EdgeInsets.all(8),
                            icon: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8)),
                              child: Icon(
                                Icons.close_rounded, 
                                color: Color(0xFF64748B),
                                size: 16)))),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () {
                            // Action pour ouvrir les filtres avancés
                            _showAdvancedFilters();
                          },
                          iconSize: 20,
                          padding: EdgeInsets.all(8),
                          icon: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Color(0xFFE2E8F0))),
                            child: Icon(
                              Icons.tune_rounded, 
                              color: Color(0xFF6366F1),
                              size: 16)))),
                    ]),
                  
                  const SizedBox(height: 16),
                  
                  // Filtres horizontaux compacts
                  Row(
                    children: [
                      _buildCompactFilterChip('Toutes', _currentFilter == 'all', Icons.all_inclusive),
                      const SizedBox(width: 8),
                      _buildCompactFilterChip('Notes', _currentFilter == 'notes', Icons.note_outlined),
                      const SizedBox(width: 8),
                      _buildCompactFilterChip('Surlignés', _currentFilter == 'highlights', Icons.highlight_outlined),
                    ]),
                ]))),
          
          // Contenu des notes sans espaces inutiles
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (totalNotes == 0 && totalHighlights == 0 && totalFavorites == 0) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFE2E8F0))),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 48,
                              color: Color(0xFF94A3B8)),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune note trouvée',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569))),
                            const SizedBox(height: 8),
                            Text(
                              'Commencez à prendre des notes lors de votre lecture',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Color(0xFF94A3B8)),
                              textAlign: TextAlign.center),
                          ])));
                  }
                  
                  return _buildNotesContent();
                },
                childCount: 1))),
        ]));
  }

  Widget _buildCompactFilterChip(String label, bool isSelected, IconData icon) {
    Color getFilterColor() {
      switch (label) {
        case 'Notes':
          return Color(0xFF10B981);
        case 'Surlignés':
          return Color(0xFFF59E0B);
        default:
          return Color(0xFF6366F1);
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          switch (label) {
            case 'Toutes':
              _currentFilter = 'all';
              break;
            case 'Notes':
              _currentFilter = 'notes';
              break;
            case 'Surlignés':
              _currentFilter = 'highlights';
              break;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? getFilterColor() : Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? getFilterColor() : Color(0xFFE2E8F0),
            width: 1)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Theme.of(context).colorScheme.surfaceColor : Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Theme.of(context).colorScheme.surfaceColor : Color(0xFF64748B))),
          ])));
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 20),
            Text(
              'Filtres avancés',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
            SizedBox(height: 20),
            // Ici, on pourrait ajouter plus d'options de filtrage
            Text(
              'Fonctionnalité à venir...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Color(0xFF64748B))),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              child: Text('Fermer')),
          ])));
  }

  Widget _buildNotesContent() {
    List<Map<String, dynamic>> allItems = [];
    
    // Ajouter les notes avec contenu
    _notes.entries.forEach((entry) {
      final key = entry.key;
      final note = entry.value;
      if (note.isNotEmpty) {
        allItems.add({
          'type': 'note',
          'verseKey': key,
          'content': _getVerseText(key), // Texte du verset
          'note': note, // Note de l'utilisateur
          'isHighlighted': _highlights.containsKey(key),
          'isFavorite': _favorites.contains(key),
        });
      }
    });
    
    // Ajouter les surlignages (même ceux sans notes)
    _highlights.entries.forEach((entry) {
      final key = entry.key;
      final highlight = entry.value;
      
      // Ne pas dupliquer si déjà ajouté comme note
      bool alreadyAdded = allItems.any((item) => item['verseKey'] == key);
      if (!alreadyAdded) {
        allItems.add({
          'type': 'highlight',
          'verseKey': key,
          'content': _getVerseText(key), // Récupérer le texte du verset
          'highlightColor': highlight.color,
          'isHighlighted': true,
          'isFavorite': _favorites.contains(key),
        });
      }
    });
    
    // Ajouter les favoris (même ceux sans notes ni surlignages)
    _favorites.forEach((key) {
      bool alreadyAdded = allItems.any((item) => item['verseKey'] == key);
      if (!alreadyAdded) {
        allItems.add({
          'type': 'favorite',
          'verseKey': key,
          'content': _getVerseText(key),
          'isHighlighted': _highlights.containsKey(key),
          'isFavorite': true,
        });
      }
    });
    
    // Filtrer selon le filtre actuel
    List<Map<String, dynamic>> filteredItems = [];
    allItems.forEach((item) {
      switch (_currentFilter) {
        case 'notes':
          if (item['type'] == 'note') filteredItems.add(item);
          break;
        case 'highlights':
          if (item['isHighlighted']) filteredItems.add(item);
          break;
        default: // 'all'
          filteredItems.add(item);
          break;
      }
    });

    // Filtrer par recherche si une recherche est active
    if (_notesSearchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) {
        // Rechercher dans le contenu du verset
        final content = item['content']?.toString().toLowerCase() ?? '';
        // Rechercher dans les notes utilisateur
        final note = item['note']?.toString().toLowerCase() ?? '';
        // Rechercher dans la référence (livre chapitre:verset)
        final verseKey = item['verseKey']?.toString().toLowerCase() ?? '';
        
        return content.contains(_notesSearchQuery) ||
               note.contains(_notesSearchQuery) ||
               verseKey.contains(_notesSearchQuery);
      }).toList();
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _notesSearchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.sticky_note_2_outlined, 
              size: 64, 
              color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.4)
            ),
            SizedBox(height: 16),
            Text(
              _notesSearchQuery.isNotEmpty 
                ? 'Aucun résultat pour "${_notesSearchQuery}"'
                : 'Aucun élément trouvé',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
            SizedBox(height: 8),
            Text(
              _notesSearchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés ou vérifiez l\'orthographe'
                : 'Commencez à prendre des notes\nou surligner des versets',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.5))),
          ]));
    }

    return Column(
      children: filteredItems.map((item) {
        return _buildItemCard(item);
      }).toList());
  }

  String _getVerseText(String verseKey) {
    // Extraire le livre, chapitre et verset de la clé
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final bookName = parts[0];
      final chapterNum = int.tryParse(parts[1]) ?? 1;
      final verseNum = int.tryParse(parts[2]) ?? 1;
      
      // Chercher dans les livres chargés
      final book = _bibleService.books.firstWhere(
        (b) => b.name == bookName,
        orElse: () => BibleBook(name: bookName, chapters: []));
      
      if (book.chapters.isNotEmpty && 
          chapterNum <= book.chapters.length && 
          chapterNum > 0) {
        final chapterVerses = book.chapters[chapterNum - 1];
        if (verseNum <= chapterVerses.length && verseNum > 0) {
          return chapterVerses[verseNum - 1];
        }
      }
    }
    return 'Texte non disponible';
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final verseKey = item['verseKey'] as String;
    final content = item['content'] as String;
    final type = item['type'] as String;
    final isHighlighted = item['isHighlighted'] as bool;
    final isFavorite = item['isFavorite'] as bool;
    final hasNote = type == 'note';
    final isHighlightItem = type == 'highlight';
    
    // Couleurs selon le type
    Color getCardAccentColor() {
      if (hasNote) return Color(0xFF10B981);
      if (isHighlightItem) return Color(0xFFF59E0B);
      if (isFavorite) return Color(0xFFEF4444);
      return Color(0xFF6366F1);
    }

    return GestureDetector(
      onTap: () => _goToVerse(verseKey),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: getCardAccentColor().withOpacity(0.15),
            width: 1.5),
          boxShadow: [
            BoxShadow(
              color: getCardAccentColor().withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 8)),
            BoxShadow(
              color: Color(0xFF000000).withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2)),
          ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec référence et badges améliorés
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    getCardAccentColor().withOpacity(0.05),
                    getCardAccentColor().withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              child: Row(
                children: [
                  // Icône du type principal
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          getCardAccentColor(),
                          getCardAccentColor().withOpacity(0.8),
                        ]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: getCardAccentColor().withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4)),
                      ]),
                    child: Icon(
                      hasNote 
                        ? Icons.sticky_note_2_rounded
                        : isHighlightItem 
                          ? Icons.highlight_rounded
                          : Icons.favorite_rounded,
                      color: Theme.of(context).colorScheme.surfaceColor,
                      size: 20)),
                  
                  SizedBox(width: 16),
                  
                  // Référence
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getVerseReference(verseKey),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                        SizedBox(height: 4),
                        Text(
                          hasNote 
                            ? 'Note personnelle'
                            : isHighlightItem 
                              ? 'Verset surligné'
                              : 'Verset favori',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: getCardAccentColor(),
                            fontWeight: FontWeight.w600)),
                      ])),
                  
                  // Badges d'état
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasNote)
                        _buildStatusBadge(
                          icon: Icons.sticky_note_2_rounded,
                          label: 'Note',
                          color: Color(0xFF10B981)),
                      if (isHighlighted && !hasNote) ...[
                        SizedBox(height: 4),
                        _buildStatusBadge(
                          icon: Icons.highlight_rounded,
                          label: 'Surligné',
                          color: Color(0xFFF59E0B)),
                      ],
                      if (isFavorite && !hasNote && !isHighlightItem) ...[
                        SizedBox(height: 4),
                        _buildStatusBadge(
                          icon: Icons.favorite_rounded,
                          label: 'Favori',
                          color: Color(0xFFEF4444)),
                      ],
                    ]),
                ])),
            
            // Contenu principal redesigné
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texte du verset dans un conteneur stylisé
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: getCardAccentColor().withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: getCardAccentColor().withOpacity(0.1),
                        width: 1)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icône de citation
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: getCardAccentColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                              child: Icon(
                                Icons.format_quote_rounded,
                                color: getCardAccentColor(),
                                size: 16)),
                            SizedBox(width: 10),
                            Text(
                              'Verset biblique',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: getCardAccentColor())),
                          ]),
                        SizedBox(height: 12),
                        
                        // Texte du verset
                        Text(
                          content,
                          style: GoogleFonts.crimsonText(
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            fontStyle: isHighlightItem ? FontStyle.italic : FontStyle.normal)),
                      ])),
                  
                  // Note utilisateur (si présente)
                  if (hasNote && item.containsKey('note')) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF10B981).withOpacity(0.08),
                            Color(0xFF10B981).withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Color(0xFF10B981).withOpacity(0.2),
                          width: 1)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(8)),
                                child: Icon(
                                  Icons.edit_note_rounded, 
                                  size: 16, 
                                  color: Theme.of(context).colorScheme.surfaceColor
                                )),
                              SizedBox(width: 10),
                              Text(
                                'Ma réflexion personnelle',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF065F46))),
                            ]),
                          SizedBox(height: 10),
                          Text(
                            item['note'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Color(0xFF064E3B),
                              height: 1.5,
                              fontWeight: FontWeight.w500)),
                        ])),
                  ],
                ])),
            
            // Actions redesignées
            Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _goToVerse(verseKey),
                      icon: Icon(Icons.menu_book_rounded, size: 16),
                      label: Text('Aller au verset'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                        backgroundColor: Color(0xFF6366F1),
                        elevation: 2,
                        shadowColor: Color(0xFF6366F1).withOpacity(0.3),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))))),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareNote(verseKey, content),
                      icon: Icon(Icons.share_rounded, size: 16),
                      label: Text('Partager'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(0xFF059669),
                        backgroundColor: Theme.of(context).colorScheme.surfaceColor,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Color(0xFF059669).withOpacity(0.3), width: 1))))),
                ])),
          ])));
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
        ]));
  }

  String _getVerseReference(String verseKey) {
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final book = parts[0];
      final chapter = parts[1];
      final verse = parts[2];
      return '$book $chapter:$verse';
    }
    return verseKey;
  }

  void _showNotePopup(String verseKey, String noteText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        Icons.sticky_note_2,
                        color: Color(0xFF10B981),
                        size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937))),
                          Text(
                            _getVerseReference(verseKey),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w500)),
                        ])),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
                  ]),
                
                const SizedBox(height: 16),
                
                // Contenu de la note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF10B981).withOpacity(0.2))),
                  child: Text(
                    noteText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5))),
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _goToVerse(verseKey);
                        },
                        icon: Icon(Icons.book_outlined, size: 16),
                        label: Text('Aller au verset'),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 12)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF10B981),
                          foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                        child: Text('Fermer'))),
                  ]),
              ])));
      });
  }

  void _goToVerse(String verseKey) {
    // Extraire les informations du verset
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final bookName = parts[0];
      final chapterNum = int.tryParse(parts[1]) ?? 1;
      final verseNum = int.tryParse(parts[2]) ?? 1;
      
      setState(() {
        // Activer le flag de navigation depuis Notes
        _isNavigatingFromNotes = true;
        
        // Définir le livre et chapitre sélectionnés
        _selectedBook = bookName;
        _selectedChapter = chapterNum;
        
        // Changer vers l'onglet lecture
        _tabController.index = 1;
      });
      
      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigation vers $bookName $chapterNum:$verseNum'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF6366F1)));
    }
  }

  void _shareNote(String verseKey, String note) {
    // Implémenter le partage
    final parts = verseKey.split('_');
    if (parts.length >= 3) {
      final book = parts[0];
      final chapter = parts[1];
      final verse = parts[2];
      
      final shareText = '''
"$note"

Verset: $book $chapter:$verse

✝️ Partagé depuis l'app Jubilé Tabernacle France
''';
      
      Share.share(
        shareText,
        subject: 'Ma note biblique - $book $chapter:$verse');
    } else {
      Share.share(
        '"$note"\n\n✝️ Partagé depuis l\'app Jubilé Tabernacle France',
        subject: 'Ma note biblique');
    }
  }

  // Méthodes pour la sélection multiple
  void _handleVerseTap(String verseKey, int verseNumber, String verseText, String bookName, int chapter) {
    if (_isMultiSelectMode) {
      _toggleVerseSelection(verseKey);
    } else {
      _showVerseActions(BibleVerse(
        book: bookName,
        chapter: chapter,
        verse: verseNumber,
        text: verseText));
    }
  }

  void _handleVerseLongPress(String verseKey, int verseNumber, String verseText, String bookName, int chapter) {
    if (!_isMultiSelectMode) {
      _startMultiSelection(verseKey);
    } else {
      _toggleVerseSelection(verseKey);
    }
  }

  void _toggleVerseSelection(String verseKey) {
    setState(() {
      if (_selectedVerses.contains(verseKey)) {
        _selectedVerses.remove(verseKey);
        if (_selectedVerses.isEmpty) {
          _exitMultiSelectMode();
        }
      } else {
        _selectedVerses.add(verseKey);
      }
    });
    
    // Afficher la toolbar si des versets sont sélectionnés
    if (_selectedVerses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMultiSelectToolbar();
      });
    }
  }

  void _startMultiSelection(String verseKey) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedVerses.clear();
      _selectedVerses.add(verseKey);
      _selectionStartVerse = verseKey;
    });
    
    // Message d'aide pour le mode continu
    if (!_versePerLine) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mode sélection activé ! Tapez sur chaque verset pour l\'ajouter/retirer de la sélection.',
            style: TextStyle(fontSize: 14)),
          backgroundColor: Theme.of(context).colorScheme.primaryColor,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating));
    }
    
    // Afficher la barre d'outils de sélection
    _showMultiSelectToolbar();
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedVerses.clear();
      _selectionStartVerse = null;
    });
  }

  BoxDecoration? _getVerseDecoration(String verseKey, bool isHighlighted, bool isSelected) {
    if (isSelected && isHighlighted) {
      return BoxDecoration(
        color: _getHighlightColor(verseKey),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primaryColor,
            width: 3)));
    } else if (isSelected) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primaryColor,
            width: 3)));
    } else if (isHighlighted) {
      return BoxDecoration(
        color: _getHighlightColor(verseKey),
        borderRadius: BorderRadius.circular(6));
    }
    return null;
  }

  void _showMultiSelectToolbar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5)),
          ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec nombre de versets sélectionnés
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedVerses.length} verset${_selectedVerses.length > 1 ? 's' : ''} sélectionné${_selectedVerses.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937)))),
                IconButton(
                  onPressed: _exitMultiSelectMode,
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))),
              ]),
            
            const SizedBox(height: 20),
            
            // Actions pour la sélection multiple
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMultiSelectAction(
                  'Surligner',
                  Icons.highlight,
                  Color(0xFFF59E0B),
                  () => _highlightSelectedVerses()),
                _buildMultiSelectAction(
                  'Favoris',
                  Icons.favorite,
                  Color(0xFFEF4444),
                  () => _favoriteSelectedVerses()),
                _buildMultiSelectAction(
                  'Noter',
                  Icons.sticky_note_2,
                  Color(0xFF10B981),
                  () => _noteSelectedVerses()),
                _buildMultiSelectAction(
                  'Copier',
                  Icons.copy,
                  Color(0xFF6366F1),
                  () => _copySelectedVerses()),
                _buildMultiSelectAction(
                  'Partager',
                  Icons.share,
                  Color(0xFF8B5CF6),
                  () => _shareSelectedVerses()),
              ]),
            
            const SizedBox(height: 16),
            
            // Bouton pour tout désélectionner
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  _exitMultiSelectMode();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(
                  'Annuler la sélection',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.6))))),
          ])));
  }

  Widget _buildMultiSelectAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color)),
          ])));
  }

  void _highlightSelectedVerses() {
    setState(() {
      for (String verseKey in _selectedVerses) {
        _highlights[verseKey] = BibleHighlight(
          verseKey: verseKey,
          color: 'yellow',
          style: 'highlight',
          createdAt: DateTime.now());
      }
    });
    _savePrefs();
    _exitMultiSelectMode();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedVerses.length} verset${_selectedVerses.length > 1 ? 's' : ''} surligné${_selectedVerses.length > 1 ? 's' : ''}'),
        backgroundColor: Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _favoriteSelectedVerses() {
    setState(() {
      _favorites.addAll(_selectedVerses);
    });
    _savePrefs();
    _exitMultiSelectMode();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedVerses.length} verset${_selectedVerses.length > 1 ? 's' : ''} ajouté${_selectedVerses.length > 1 ? 's' : ''} aux favoris'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _noteSelectedVerses() {
    _exitMultiSelectMode();
    
    // Afficher un dialog pour ajouter une note commune
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ajouter une note',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Votre note...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          maxLines: 3,
          onChanged: (value) => _tempNote = value),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (_tempNote.isNotEmpty) {
                setState(() {
                  for (String verseKey in _selectedVerses) {
                    _notes[verseKey] = _tempNote;
                  }
                });
                _savePrefs();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Note ajoutée à ${_selectedVerses.length} verset${_selectedVerses.length > 1 ? 's' : ''}'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              }
            },
            child: Text('Ajouter')),
        ]));
  }

  void _copySelectedVerses() {
    final selectedTexts = _selectedVerses.map((verseKey) {
      final parts = verseKey.split('_');
      final book = parts[0];
      final chapter = parts[1];
      final verse = parts[2];
      final text = _getVerseText(verseKey);
      return '$book $chapter:$verse - $text';
    }).join('\n\n');
    
    Clipboard.setData(ClipboardData(text: selectedTexts));
    _exitMultiSelectMode();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedVerses.length} verset${_selectedVerses.length > 1 ? 's' : ''} copié${_selectedVerses.length > 1 ? 's' : ''}'),
        backgroundColor: Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _shareSelectedVerses() {
    final selectedTexts = _selectedVerses.map((verseKey) {
      final parts = verseKey.split('_');
      final book = parts[0];
      final chapter = parts[1];
      final verse = parts[2];
      final text = _getVerseText(verseKey);
      return '$book $chapter:$verse - $text';
    }).join('\n\n');
    
    Share.share(selectedTexts);
    _exitMultiSelectMode();
  }

  String _tempNote = '';

  // Méthode pour afficher un aperçu du texte
  String _getPreviewText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    
    // Trouver le dernier espace avant la limite pour éviter de couper au milieu d'un mot
    int cutPosition = maxLength;
    for (int i = maxLength - 1; i >= 0; i--) {
      if (text[i] == ' ') {
        cutPosition = i;
        break;
      }
    }
    
    return '${text.substring(0, cutPosition)}...';
  }

  // Méthode pour ouvrir la page du contenu quotidien complet
  void _openDailyContentPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DailyContentPage(
          initialQuote: _branhamQuote)));
  }
}
