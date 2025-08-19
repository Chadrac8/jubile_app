import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme.dart';
import '../models/branham_quote.dart';
import '../../../theme.dart';
import '../../../services/branham_scraping_service.dart';
import '../../../theme.dart';

class GoldenNuggetsView extends StatefulWidget {
  const GoldenNuggetsView({Key? key}) : super(key: key);

  @override
  State<GoldenNuggetsView> createState() => _GoldenNuggetsViewState();
}

class _GoldenNuggetsViewState extends State<GoldenNuggetsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BranhamScrapingService _branhamService = BranhamScrapingService.instance;
  
  List<BranhamQuote> _quotes = [];
  List<BranhamQuote> _dailyQuotes = [];
  List<BranhamQuote> _favoriteQuotes = [];
  List<BranhamQuote> _filteredQuotes = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Toutes';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Toutes',
    'Foi',
    'Prière',
    'Espoir',
    'Amour',
    'Salut',
    'Guérison',
    'Prophétie',
    'Église',
    'Vie chrétienne',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les citations du jour
      final dailyQuote = await _branhamService.getQuoteOfTheDay();
      if (dailyQuote != null) {
        // Convertir BranhamQuoteModel vers BranhamQuote
        final quote = BranhamQuote(
          text: dailyQuote.text,
          reference: dailyQuote.reference,
          category: 'Citation du jour',
          date: DateTime.now(),
          dailyBread: dailyQuote.dailyBread,
          dailyBreadReference: dailyQuote.dailyBreadReference);
        _dailyQuotes = [quote];
      }

      // Générer des citations d'exemple pour la démonstration
      _quotes = _generateExampleQuotes();
      _filteredQuotes = List.from(_quotes);
      
    } catch (e) {
      print('Erreur lors du chargement des citations: $e');
      _quotes = _generateExampleQuotes();
      _filteredQuotes = List.from(_quotes);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<BranhamQuote> _generateExampleQuotes() {
    return [
      BranhamQuote(
        text: "La foi est quelque chose que vous avez ; elle n'est pas quelque chose que vous obtenez.",
        reference: "La Foi, 1957",
        category: "Foi",
        date: DateTime.now().subtract(Duration(days: 1))),
      BranhamQuote(
        text: "Dieu ne vous appelle jamais à faire quelque chose sans vous donner la grâce de l'accomplir.",
        reference: "La Grâce de Dieu, 1962",
        category: "Foi",
        date: DateTime.now().subtract(Duration(days: 2))),
      BranhamQuote(
        text: "La prière change les choses. Elle change les circonstances, elle change les gens.",
        reference: "Comment prier efficacement, 1959",
        category: "Prière",
        date: DateTime.now().subtract(Duration(days: 3))),
      BranhamQuote(
        text: "L'espoir est l'ancre de l'âme, sûre et solide.",
        reference: "L'Espérance chrétienne, 1960",
        category: "Espoir",
        date: DateTime.now().subtract(Duration(days: 4))),
      BranhamQuote(
        text: "L'amour couvre une multitude de péchés.",
        reference: "L'Amour divin, 1958",
        category: "Amour",
        date: DateTime.now().subtract(Duration(days: 5))),
      BranhamQuote(
        text: "Le salut est un don gratuit de Dieu, il ne peut être mérité.",
        reference: "Le Don gratuit de Dieu, 1963",
        category: "Salut",
        date: DateTime.now().subtract(Duration(days: 6))),
      BranhamQuote(
        text: "La guérison divine fait partie de l'expiation.",
        reference: "Jésus-Christ le même hier, aujourd'hui et éternellement, 1958",
        category: "Guérison",
        date: DateTime.now().subtract(Duration(days: 7))),
      BranhamQuote(
        text: "L'Église est appelée à être un peuple séparé, sanctifié pour Dieu.",
        reference: "L'Église et sa mission, 1961",
        category: "Église",
        date: DateTime.now().subtract(Duration(days: 8))),
      BranhamQuote(
        text: "Vivez chaque jour comme si c'était le dernier, car peut-être que c'est le cas.",
        reference: "La Seconde venue de Christ, 1964",
        category: "Vie chrétienne",
        date: DateTime.now().subtract(Duration(days: 9))),
      BranhamQuote(
        text: "La Parole de Dieu est plus tranchante qu'une épée à deux tranchants.",
        reference: "La Parole parlée, 1962",
        category: "Prophétie",
        date: DateTime.now().subtract(Duration(days: 10))),
    ];
  }

  void _filterQuotes() {
    setState(() {
      _filteredQuotes = _quotes.where((quote) {
        final matchesSearch = _searchQuery.isEmpty ||
            quote.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            quote.reference.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'Toutes' ||
            quote.category == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterQuotes();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterQuotes();
  }

  void _shareQuote(BranhamQuote quote) {
    Share.share(
      '"${quote.text}"\n\n- ${quote.reference}\n\n✝️ Partagé depuis l\'app Jubilé Tabernacle France',
      subject: 'Citation de William Marrion Branham');
  }

  void _toggleFavorite(BranhamQuote quote) {
    setState(() {
      if (_favoriteQuotes.contains(quote)) {
        _favoriteQuotes.remove(quote);
      } else {
        _favoriteQuotes.add(quote);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favoriteQuotes.contains(quote)
              ? 'Citation ajoutée aux favoris'
              : 'Citation retirée des favoris'),
        duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textTertiaryColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textTertiaryColor),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          'Pépites d\'or',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textTertiaryColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textTertiaryColor),
            onPressed: _loadQuotes),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber[700],
          unselectedLabelColor: AppTheme.textTertiaryColor,
          indicatorColor: Colors.amber[700],
          tabs: [
            Tab(text: 'Aujourd\'hui'),
            Tab(text: 'Explorer'),
            Tab(text: 'Favoris'),
          ])),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.amber[700]),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des pépites d\'or...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.textTertiaryColor)),
                ]))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildExploreTab(),
                _buildFavoritesTab(),
              ]));
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Citation du jour',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textTertiaryColor)),
          SizedBox(height: 8),
          Text(
            'Méditation quotidienne avec William Marrion Branham',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textTertiaryColor)),
          SizedBox(height: 24),
          
          if (_dailyQuotes.isNotEmpty)
            _buildQuoteCard(_dailyQuotes.first, isHighlighted: true)
          else
            _buildQuoteCard(_quotes.first, isHighlighted: true),
          
          SizedBox(height: 32),
          
          Text(
            'Citations récentes',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textTertiaryColor)),
          SizedBox(height: 16),
          
          ...(_quotes.take(3).map((quote) => 
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: _buildQuoteCard(quote))
          )),
        ]));
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          color: AppTheme.surfaceColor,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher une citation...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textTertiaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.textTertiaryColor)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.textTertiaryColor)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.amber[700]!)))),
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) => _onCategoryChanged(category),
                        selectedColor: Colors.amber[100],
                        checkmarkColor: Colors.amber[700],
                        labelStyle: TextStyle(
                          color: _selectedCategory == category
                              ? Colors.amber[700]
                              : AppTheme.textTertiaryColor)))).toList())),
            ])),
        
        Expanded(
          child: _filteredQuotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppTheme.textTertiaryColor),
                      SizedBox(height: 16),
                      Text(
                        'Aucune citation trouvée',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: AppTheme.textTertiaryColor)),
                      SizedBox(height: 8),
                      Text(
                        'Essayez avec d\'autres mots-clés',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiaryColor)),
                    ]))
              : ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: _filteredQuotes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _buildQuoteCard(_filteredQuotes[index]));
                  })),
      ]);
  }

  Widget _buildFavoritesTab() {
    return _favoriteQuotes.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border,
                  size: 64,
                  color: AppTheme.textTertiaryColor),
                SizedBox(height: 16),
                Text(
                  'Aucune citation favorite',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: AppTheme.textTertiaryColor)),
                SizedBox(height: 8),
                Text(
                  'Ajoutez vos citations préférées en tapant sur l\'étoile',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textTertiaryColor),
                  textAlign: TextAlign.center),
              ]))
        : ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: _favoriteQuotes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildQuoteCard(_favoriteQuotes[index]));
            });
  }

  Widget _buildQuoteCard(BranhamQuote quote, {bool isHighlighted = false}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.amber[50]!, AppTheme.warningColor])
            : null,
        color: isHighlighted ? null : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: Colors.amber.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? Colors.amber.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: isHighlighted ? 20 : 10,
            offset: Offset(0, isHighlighted ? 4 : 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHighlighted ? Colors.amber[100] : AppTheme.textTertiaryColor,
                  borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  Icons.format_quote,
                  color: isHighlighted ? Colors.amber[700] : AppTheme.textTertiaryColor,
                  size: 20)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isHighlighted ? Colors.amber[700] : AppTheme.textTertiaryColor)),
                    Text(
                      _formatDate(quote.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textTertiaryColor)),
                  ])),
              IconButton(
                onPressed: () => _toggleFavorite(quote),
                icon: Icon(
                  _favoriteQuotes.contains(quote)
                      ? Icons.star
                      : Icons.star_border,
                  color: _favoriteQuotes.contains(quote)
                      ? Colors.amber[700]
                      : AppTheme.textTertiaryColor)),
              IconButton(
                onPressed: () => _shareQuote(quote),
                icon: Icon(
                  Icons.share,
                  color: AppTheme.textTertiaryColor)),
            ]),
          
          SizedBox(height: 16),
          
          Text(
            quote.text,
            style: GoogleFonts.crimsonText(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.4,
              color: AppTheme.textTertiaryColor,
              fontWeight: FontWeight.w500)),
          
          SizedBox(height: 16),
          
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isHighlighted ? Colors.amber[100] : AppTheme.textTertiaryColor,
                borderRadius: BorderRadius.circular(20)),
              child: Text(
                quote.reference,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? Colors.amber[800] : AppTheme.textTertiaryColor)))),
        ]));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
