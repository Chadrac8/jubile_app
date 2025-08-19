import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_article.dart';
import '../services/bible_article_service.dart';
import 'bible_article_form_view.dart';

class BibleArticleDetailView extends StatefulWidget {
  final BibleArticle article;
  final bool isAdmin;

  const BibleArticleDetailView({
    super.key,
    required this.article,
    this.isAdmin = false,
  });

  @override
  State<BibleArticleDetailView> createState() => _BibleArticleDetailViewState();
}

class _BibleArticleDetailViewState extends State<BibleArticleDetailView> {
  final BibleArticleService _articleService = BibleArticleService.instance;
  late BibleArticle _article;
  bool _isBookmarked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _loadData();
    _markAsRead();
  }

  Future<void> _loadData() async {
    try {
      // Vérifier si l'article est en favoris
      final stats = await _articleService.getReadingStats('default', _article.id);
      setState(() {
        _isBookmarked = stats?.isBookmarked ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    await _articleService.markArticleAsRead(_article.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()))
                : _buildContent(theme)),
        ]));
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: theme.primaryColor,
      foregroundColor: AppTheme.surfaceColor,
      actions: [
        IconButton(
          onPressed: _toggleBookmark,
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: AppTheme.surfaceColor),
          tooltip: _isBookmarked ? 'Retirer des favoris' : 'Ajouter aux favoris'),
        if (widget.isAdmin)
          PopupMenuButton<String>(
            onSelected: _handleAdminAction,
            icon: Icon(Icons.settings, color: AppTheme.surfaceColor),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ])),
              PopupMenuItem(
                value: _article.isPublished ? 'unpublish' : 'publish',
                child: Row(
                  children: [
                    Icon(
                      _article.isPublished 
                          ? Icons.visibility_off_outlined 
                          : Icons.visibility_outlined,
                      size: 18),
                    const SizedBox(width: 8),
                    Text(_article.isPublished ? 'Dépublier' : 'Publier'),
                  ])),
            ]),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.8),
              ])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      _article.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.surfaceColor))),
                  const SizedBox(height: 12),
                  
                  // Titre
                  Text(
                    _article.title,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.surfaceColor)),
                ]))))));
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadata(theme),
          const SizedBox(height: 24),
          _buildSummary(theme),
          const SizedBox(height: 24),
          _buildContent1(theme),
          if (_article.bibleReferences.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildBibleReferences(theme),
          ],
          if (_article.tags.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildTags(theme),
          ],
          const SizedBox(height: 32),
          _buildAuthorInfo(theme),
        ]));
  }

  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.person_outline,
          size: 16,
          color: theme.hintColor),
        const SizedBox(width: 4),
        Text(
          _article.author,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.hintColor)),
        const SizedBox(width: 16),
        Icon(
          Icons.access_time_outlined,
          size: 16,
          color: theme.hintColor),
        const SizedBox(width: 4),
        Text(
          '${_article.readingTimeMinutes} min de lecture',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.hintColor)),
        const Spacer(),
        Icon(
          Icons.visibility_outlined,
          size: 16,
          color: theme.hintColor),
        const SizedBox(width: 4),
        Text(
          '${_article.viewCount} lectures',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.hintColor)),
      ]);
  }

  Widget _buildSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
          width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.primaryColor,
                size: 20),
              const SizedBox(width: 8),
              Text(
                'Résumé',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor)),
            ]),
          const SizedBox(height: 12),
          Text(
            _article.summary,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: theme.textTheme.bodyLarge?.color)),
        ]));
  }

  Widget _buildContent1(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Article',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color)),
        const SizedBox(height: 16),
        Text(
          _article.content,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.7,
            color: theme.textTheme.bodyLarge?.color)),
      ]);
  }

  Widget _buildBibleReferences(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: theme.primaryColor,
              size: 20),
            const SizedBox(width: 8),
            Text(
              'Références bibliques',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color)),
          ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _article.bibleReferences.map((ref) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1)),
            child: Text(
              ref.displayText,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color)))).toList()),
      ]);
  }

  Widget _buildTags(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: theme.primaryColor,
              size: 20),
            const SizedBox(width: 8),
            Text(
              'Mots-clés',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color)),
          ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _article.tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16)),
            child: Text(
              '#$tag',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor)))).toList()),
      ]);
  }

  Widget _buildAuthorInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              _article.author.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _article.author,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleMedium?.color)),
                const SizedBox(height: 4),
                Text(
                  'Publié le ${_formatDate(_article.createdAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.hintColor)),
              ])),
        ]));
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _toggleBookmark() async {
    try {
      await _articleService.toggleBookmark(_article.id);
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked 
                ? 'Article ajouté aux favoris'
                : 'Article retiré des favoris')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')));
    }
  }

  void _handleAdminAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BibleArticleFormView(article: _article))).then((result) {
          if (result != null) {
            setState(() {
              _article = result;
            });
          }
        });
        break;
      case 'publish':
      case 'unpublish':
        _togglePublishStatus();
        break;
    }
  }

  Future<void> _togglePublishStatus() async {
    try {
      final updatedArticle = _article.copyWith(isPublished: !_article.isPublished);
      await _articleService.updateArticle(updatedArticle);
      
      setState(() {
        _article = updatedArticle;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedArticle.isPublished 
                ? 'Article publié avec succès'
                : 'Article dépublié avec succès')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')));
    }
  }
}
