import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reading_plan.dart';
import '../bible_service.dart';
import '../bible_model.dart';

class DailyReadingView extends StatefulWidget {
  final ReadingPlan plan;
  final ReadingPlanDay day;
  final UserReadingProgress progress;
  final Function(String? note) onCompleted;

  const DailyReadingView({
    Key? key,
    required this.plan,
    required this.day,
    required this.progress,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<DailyReadingView> createState() => _DailyReadingViewState();
}

class _DailyReadingViewState extends State<DailyReadingView> {
  final BibleService _bibleService = BibleService();
  final TextEditingController _noteController = TextEditingController();
  final PageController _pageController = PageController();
  
  List<List<BibleVerse>> _readingsVerses = [];
  bool _isLoading = true;
  bool _isCompleting = false;
  int _currentReadingIndex = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadReadings();
    _isCompleted = widget.progress.completedDays.contains(widget.day.day);
    
    // Charger la note existante si elle existe
    final existingNote = widget.progress.dayNotes[widget.day.day];
    if (existingNote != null) {
      _noteController.text = existingNote;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReadings() async {
    setState(() => _isLoading = true);
    
    try {
      await _bibleService.loadBible();
      
      final readingsVerses = <List<BibleVerse>>[];
      
      for (final reading in widget.day.readings) {
        final verses = _getVersesForReading(reading);
        readingsVerses.add(verses);
      }
      
      setState(() {
        _readingsVerses = readingsVerses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')));
      }
    }
  }

  List<BibleVerse> _getVersesForReading(BibleReference reading) {
    final verses = <BibleVerse>[];
    
    if (reading.chapter == null) {
      // Livre entier - prendre les premiers chapitres
      final book = _bibleService.books.firstWhere(
        (b) => b.name == reading.book,
        orElse: () => BibleBook(name: '', chapters: []));
      
      if (book.chapters.isNotEmpty) {
        for (int c = 0; c < book.chapters.length && c < 3; c++) {
          for (int v = 0; v < book.chapters[c].length && v < 10; v++) {
            verses.add(BibleVerse(
              book: reading.book,
              chapter: c + 1,
              verse: v + 1,
              text: book.chapters[c][v]));
          }
        }
      }
    } else {
      // Chapitre spécifique
      final startChapter = reading.chapter!;
      final endChapter = reading.endChapter ?? startChapter;
      
      for (int c = startChapter; c <= endChapter; c++) {
        final book = _bibleService.books.firstWhere(
          (b) => b.name == reading.book,
          orElse: () => BibleBook(name: '', chapters: []));
        
        if (book.chapters.length >= c) {
          final chapter = book.chapters[c - 1];
          final startVerse = (c == startChapter && reading.startVerse != null) 
              ? reading.startVerse! : 1;
          final endVerse = (c == endChapter && reading.endVerse != null) 
              ? reading.endVerse! : chapter.length;
          
          for (int v = startVerse; v <= endVerse && v <= chapter.length; v++) {
            verses.add(BibleVerse(
              book: reading.book,
              chapter: c,
              verse: v,
              text: chapter[v - 1]));
          }
        }
      }
    }
    
    return verses;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          children: [
            Text(
              'Jour ${widget.day.day}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600)),
            Text(
              widget.day.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ]),
        centerTitle: true,
        actions: [
          if (_isCompleted)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.successColor),
          const SizedBox(width: 16),
        ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Indicateur de progression entre les lectures
                if (_readingsVerses.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: List.generate(_readingsVerses.length, (index) {
                        final isActive = index == _currentReadingIndex;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index < _readingsVerses.length - 1 ? 8 : 0),
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2))));
                      }))),
                
                // Contenu des lectures
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _readingsVerses.length,
                    onPageChanged: (index) {
                      setState(() => _currentReadingIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildReadingPage(
                        theme,
                        widget.day.readings[index],
                        _readingsVerses[index]);
                    })),
                
                // Section réflexion et prière
                if (widget.day.reflection != null || widget.day.prayer != null)
                  _buildReflectionSection(theme),
                
                // Section notes
                _buildNotesSection(theme),
              ]),
      bottomNavigationBar: _buildBottomBar(theme));
  }

  Widget _buildReadingPage(
    ThemeData theme,
    BibleReference reading,
    List<BibleVerse> verses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la lecture
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book,
                  color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reading.displayText,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary))),
              ])),
          
          const SizedBox(height: 20),
          
          // Versets
          if (verses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Lecture non disponible',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    const SizedBox(height: 8),
                    Text(
                      'Cette lecture n\'est pas encore disponible dans l\'application. Vous pouvez la lire dans votre Bible personnelle.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      textAlign: TextAlign.center),
                  ])))
          else
            ...verses.map((verse) => _buildVerseWidget(theme, verse)),
        ]));
  }

  Widget _buildVerseWidget(ThemeData theme, BibleVerse verse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${verse.verse} ',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
            TextSpan(
              text: verse.text,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.6,
                color: theme.colorScheme.onSurface)),
          ])));
  }

  Widget _buildReflectionSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.day.reflection != null) ...[
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.warningColor,
                  size: 20),
                const SizedBox(width: 8),
                Text(
                  'Réflexion',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 12),
            Text(
              widget.day.reflection!,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.8))),
          ],
          
          if (widget.day.prayer != null) ...[
            if (widget.day.reflection != null) const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  color: Theme.of(context).colorScheme.errorColor,
                  size: 20),
                const SizedBox(width: 8),
                Text(
                  'Prière',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 12),
            Text(
              widget.day.prayer!,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontStyle: FontStyle.italic)),
          ],
        ]));
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: theme.colorScheme.primary,
                size: 20),
              const SizedBox(width: 8),
              Text(
                'Mes notes personnelles',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
            ]),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Écrivez vos réflexions personnelles sur cette lecture...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary))),
            style: GoogleFonts.inter(fontSize: 14)),
        ]));
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5)),
        ]),
      child: SafeArea(
        child: Row(
          children: [
            // Bouton précédent/suivant lecture
            if (_readingsVerses.length > 1) ...[
              IconButton(
                onPressed: _currentReadingIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left)),
              Text(
                '${_currentReadingIndex + 1}/${_readingsVerses.length}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7))),
              IconButton(
                onPressed: _currentReadingIndex < _readingsVerses.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right)),
              const SizedBox(width: 16),
            ],
            
            // Bouton terminer
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted 
                      ? Theme.of(context).colorScheme.successColor 
                      : theme.colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                onPressed: _isCompleting ? null : _completeDayReading,
                child: _isCompleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.surfaceColor,
                          strokeWidth: 2))
                    : Text(
                        _isCompleted ? 'Lecture terminée ✓' : 'Terminer la lecture',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600)))),
          ])));
  }

  Future<void> _completeDayReading() async {
    if (_isCompleting) return;
    
    setState(() => _isCompleting = true);
    
    try {
      final note = _noteController.text.trim();
      await widget.onCompleted(note.isEmpty ? null : note);
      
      setState(() => _isCompleted = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lecture du jour ${widget.day.day} terminée !'),
            backgroundColor: Theme.of(context).colorScheme.successColor));
        
        // Attendre un peu avant de fermer pour montrer le feedback
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }
}
