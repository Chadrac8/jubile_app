import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/theme/app_theme.dart';
import '../../services/branham_scraping_service.dart';

class DailyContentPage extends StatefulWidget {
  final BranhamQuoteModel? initialQuote;
  
  const DailyContentPage({
    Key? key,
    this.initialQuote,
  }) : super(key: key);

  @override
  State<DailyContentPage> createState() => _DailyContentPageState();
}

class _DailyContentPageState extends State<DailyContentPage> {
  final BranhamScrapingService _scrapingService = BranhamScrapingService.instance;
  BranhamQuoteModel? _quote;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      BranhamQuoteModel? quote;
      if (widget.initialQuote != null) {
        quote = widget.initialQuote;
      } else {
        quote = await _scrapingService.getQuoteOfTheDay();
      }

      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareContent() async {
    if (_quote == null) return;

    final shareText = '''
📖 Pain quotidien - ${_quote!.date}

VERSET DU JOUR :
${_quote!.dailyBread}
${_quote!.dailyBreadReference}

CITATION DU JOUR :
"${_quote!.text}"
${_quote!.sermonTitle.isNotEmpty ? '\n${_quote!.sermonTitle}' : ''}
William Marrion Branham

Source : www.branham.org
    ''';
    
    await Share.share(shareText, subject: 'Pain quotidien - ${_quote!.date}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(
              Icons.arrow_back_ios,
              color: const Color(0xFF374151),
              size: 16)),
          onPressed: () => Navigator.of(context).pop()),
        title: Text(
          'Pain quotidien',
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3)),
        centerTitle: true,
        actions: [
          if (_quote != null)
            IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  Icons.share,
                  color: AppTheme.primaryColor,
                  size: 16)),
              onPressed: _shareContent),
          const SizedBox(width: 8),
        ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        child: const Text('Réessayer')),
                    ]))
              : _quote == null
                  ? Center(
                      child: Text(
                        'Aucun contenu disponible',
                        style: TextStyle(color: theme.colorScheme.onSurface)))
                  : Container(
                      color: const Color(0xFFF8F9FA), // Background très clair style Tithe.ly
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header avec date - Style Tithe.ly
                            Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4)),
                                ]),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16)),
                                    child: Icon(
                                      Icons.today_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 28)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Pain quotidien',
                                    style: TextStyle(
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _quote!.date.isNotEmpty ? _quote!.date : _getFormattedDate(),
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                                ])),
                          
                          // Verset du jour (Pain quotidien)
                          if (_quote!.dailyBread.isNotEmpty) ...[
                            _buildVersetCard(
                              content: _quote!.dailyBread,
                              reference: _quote!.dailyBreadReference,
                              theme: theme),
                            const SizedBox(height: 48),
                          ],
                          
                          // Citation du jour
                          if (_quote!.text.isNotEmpty) ...[
                            _buildCitationCard(
                              content: _quote!.text,
                              sermonTitle: _quote!.sermonTitle,
                              theme: theme),
                            const SizedBox(height: 48),
                          ],
                          
                          // Source avec style Tithe.ly
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2)),
                              ]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(
                                    Icons.language_rounded,
                                    color: Color(0xFF10B981),
                                    size: 16)),
                                const SizedBox(width: 12),
                                Text(
                                  'Source : www.branham.org',
                                  style: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2)),
                              ])),
                        ]))));
  }

  Widget _buildVersetCard({
    required String content,
    required String reference,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et titre
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.primaryColor,
                  size: 24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verset du jour',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(
                    'Méditation quotidienne',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
                ]),
            ]),
          
          const SizedBox(height: 24),
          
          // Verset avec style moderne
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Citation mark
                Icon(
                  Icons.format_quote,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  size: 32),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: TextStyle(
                    color: const Color(0xFF1F2937),
                    fontSize: 17,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2),
                  textAlign: TextAlign.center),
              ])),
          
          // Référence avec style Tithe.ly
          if (reference.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                reference,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3),
                textAlign: TextAlign.center)),
          ],
        ]));
  }

  Widget _buildCitationCard({
    required String content,
    required String sermonTitle,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et titre
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 24)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Citation du jour',
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(
                    'Réflexion spirituelle',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
                ]),
            ]),
          
          const SizedBox(height: 24),
          
          // Citation avec style moderne
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Citation mark
                Icon(
                  Icons.format_quote,
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  size: 32),
                const SizedBox(height: 12),
                Text(
                  content,
                  style: TextStyle(
                    color: const Color(0xFF1F2937),
                    fontSize: 17,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center),
              ])),
          
          // Titre de la prédication (si disponible)
          if (sermonTitle.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        size: 16,
                        color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Prédication',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                    ]),
                  const SizedBox(height: 8),
                  Text(
                    sermonTitle,
                    style: TextStyle(
                      color: const Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                ])),
          ],
          
          const SizedBox(height: 20),
          
          // Auteur avec style Tithe.ly
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  Color(0xFF764BA2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: AppTheme.surfaceColor,
                  size: 16),
                const SizedBox(width: 8),
                const Text(
                  'William Marrion Branham',
                  style: TextStyle(
                    color: AppTheme.surfaceColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
              ])),
        ]));
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
