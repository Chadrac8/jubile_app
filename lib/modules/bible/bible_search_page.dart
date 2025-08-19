import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'bible_service.dart';
import 'bible_model.dart';

class BibleSearchPage extends StatefulWidget {
  final BibleService bibleService;

  const BibleSearchPage({
    Key? key,
    required this.bibleService,
  }) : super(key: key);

  @override
  State<BibleSearchPage> createState() => _BibleSearchPageState();
}

class _BibleSearchPageState extends State<BibleSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<BibleVerse> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  
  // Historique des recherches
  List<String> _searchHistory = [];
  
  // Suggestions populaires
  final List<String> _popularSearches = [
    'amour',
    'foi',
    'espérance',
    'paix',
    'joie',
    'force',
    'courage',
    'sagesse',
    'miséricorde',
    'grâce',
    'prière',
    'pardon',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    // Focus automatique sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadSearchHistory() {
    // TODO: Charger l'historique depuis SharedPreferences
    _searchHistory = [
      'Dieu est amour',
      'paix',
      'Psaume 23',
      'espérance',
    ];
  }

  void _saveToHistory(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.take(10).toList();
        }
      });
      // TODO: Sauvegarder dans SharedPreferences
    }
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    _saveToHistory(query);

    // Simulation d'un délai de recherche pour l'UX
    await Future.delayed(const Duration(milliseconds: 300));

    final results = widget.bibleService.search(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _buildSearchContent()),
          ])));
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1),
            width: 1))),
      child: Column(
        children: [
          // Barre de recherche avec bouton retour
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                splashRadius: 20),
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.textTertiaryColor,
                    borderRadius: BorderRadius.circular(12),
                    border: _searchFocusNode.hasFocus
                        ? Border.all(color: Theme.of(context).colorScheme.primaryColor, width: 2)
                        : null),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _performSearch,
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans la Bible...',
                      hintStyle: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.textTertiaryColor,
                        fontSize: 16),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.textTertiaryColor,
                        size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: _clearSearch,
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.textTertiaryColor,
                                size: 20),
                              splashRadius: 16)
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12)),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87)))),
            ]),
          
          // Nombre de résultats si recherche active
          if (_searchQuery.isNotEmpty && !_isSearching)
            Container(
              margin: const EdgeInsets.only(top: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_searchResults.length} résultat${_searchResults.length > 1 ? 's' : ''} pour "$_searchQuery"',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                  fontWeight: FontWeight.w500))),
        ]));
  }

  Widget _buildSearchContent() {
    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchSuggestions();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Recherche en cours...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.textTertiaryColor)),
        ]));
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final verse = _searchResults[index];
        return _buildVerseCard(verse);
      });
  }

  Widget _buildVerseCard(BibleVerse verse) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: InkWell(
        onTap: () {
          // Feedback haptic
          HapticFeedback.lightImpact();
          
          // Naviguer vers le verset dans la page de lecture
          Navigator.pop(context, {
            'book': verse.book,
            'chapter': verse.chapter,
            'verse': verse.verse,
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Référence du verset
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${verse.book} ${verse.chapter}:${verse.verse}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primaryColor))),
              
              const SizedBox(height: 12),
              
              // Texte du verset avec surbrillance
              RichText(
                text: _buildHighlightedText(verse.text, _searchQuery)),
            ]))));
  }

  TextSpan _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5));
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1) {
      // Texte avant la correspondance
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: GoogleFonts.crimsonText(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5)));
      }
      
      // Texte en surbrillance
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5,
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.w600)));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Texte restant
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: GoogleFonts.crimsonText(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5)));
    }
    
    return TextSpan(children: spans);
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.textTertiaryColor),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.textTertiaryColor)),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.textTertiaryColor)),
          ])));
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historique des recherches
          if (_searchHistory.isNotEmpty) ...[
            Text(
              'Recherches récentes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
            const SizedBox(height: 12),
            ..._searchHistory.map((query) => _buildHistoryItem(query)),
            const SizedBox(height: 24),
          ],
          
          // Suggestions populaires
          Text(
            'Recherches populaires',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((search) => _buildPopularSearchChip(search)).toList()),
        ]));
  }

  Widget _buildHistoryItem(String query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: Theme.of(context).colorScheme.textTertiaryColor,
          size: 20),
        title: Text(
          query,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.black87)),
        trailing: IconButton(
          onPressed: () {
            setState(() {
              _searchHistory.remove(query);
            });
          },
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.textTertiaryColor,
            size: 18),
          splashRadius: 16),
        onTap: () {
          _searchController.text = query;
          _performSearch(query);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12)));
  }

  Widget _buildPopularSearchChip(String search) {
    return InkWell(
      onTap: () {
        _searchController.text = search;
        _performSearch(search);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.textTertiaryColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.textTertiaryColor.withOpacity(0.2))),
        child: Text(
          search,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500))));
  }
}
