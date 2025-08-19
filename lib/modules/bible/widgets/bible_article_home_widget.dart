import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bible_article.dart';
import '../../services/bible_article_service.dart';
import '../views/bible_articles_list_view.dart';
import '../views/bible_article_detail_view.dart';

class BibleArticleHomeWidget extends StatefulWidget {
  final bool isAdmin;

  const BibleArticleHomeWidget({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<BibleArticleHomeWidget> createState() => _BibleArticleHomeWidgetState();
}

class _BibleArticleHomeWidgetState extends State<BibleArticleHomeWidget> {
  final BibleArticleService _articleService = BibleArticleService.instance;
  List<BibleArticle> _recentArticles = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final recent = await _articleService.getRecentArticles(limit: 3);
      final stats = await _articleService.getGeneralStats();
      
      setState(() {
        _recentArticles = recent;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildStats(theme),
            _buildRecentArticles(theme),
            _buildActionButtons(theme),
          ],
        ]));
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withValues(alpha: 0.8),
          ]),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12)),
            child: Icon(
              Icons.article_outlined,
              color: Theme.of(context).colorScheme.surfaceColor,
              size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Articles bibliques',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surfaceColor)),
                const SizedBox(height: 4),
                Text(
                  'Enrichissez votre compréhension des Écritures',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.surfaceColor.withValues(alpha: 0.9))),
              ])),
          if (widget.isAdmin)
            IconButton(
              onPressed: () => _navigateToAdmin(),
              icon: const Icon(
                Icons.admin_panel_settings_outlined,
                color: Theme.of(context).colorScheme.surfaceColor),
              tooltip: 'Administration'),
        ]));
  }

  Widget _buildStats(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.article_outlined,
              value: '${_stats['publishedArticles'] ?? 0}',
              label: 'Articles',
              color: theme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              icon: Icons.visibility_outlined,
              value: '${_stats['totalViews'] ?? 0}',
              label: 'Lectures',
              color: Theme.of(context).colorScheme.warningColor)),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              icon: Icons.category_outlined,
              value: '${_stats['categoriesCount'] ?? 0}',
              label: 'Catégories',
              color: Theme.of(context).colorScheme.successColor)),
        ]));
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: color.withValues(alpha: 0.8))),
        ]));
  }

  Widget _buildRecentArticles(ThemeData theme) {
    if (_recentArticles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.article_outlined,
                size: 48,
                color: theme.hintColor),
              const SizedBox(height: 16),
              Text(
                'Aucun article disponible',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: theme.hintColor)),
              if (widget.isAdmin) ...[
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre premier article',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.hintColor.withValues(alpha: 0.7))),
              ],
            ])));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Articles récents',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.titleLarge?.color)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentArticles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = _recentArticles[index];
              return _buildArticleCard(article, theme);
            }),
        ]));
  }

  Widget _buildArticleCard(BibleArticle article, ThemeData theme) {
    return InkWell(
      onTap: () => _navigateToArticleDetail(article),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(
                        article.summary,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    ])),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    article.category,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.primaryColor))),
              ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  article.author,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.hintColor)),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  '${article.readingTimeMinutes} min',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.hintColor)),
                const Spacer(),
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: theme.hintColor),
                const SizedBox(width: 4),
                Text(
                  '${article.viewCount}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.hintColor)),
              ]),
          ])));
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToAllArticles,
              icon: const Icon(Icons.library_books_outlined),
              label: Text(
                'Voir tous les articles',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))))),
          if (widget.isAdmin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _navigateToAdmin,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  'Gérer les articles',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))))),
          ],
        ]));
  }

  void _navigateToAllArticles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleArticlesListView(isAdmin: widget.isAdmin)));
  }

  void _navigateToArticleDetail(BibleArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleArticleDetailView(
          article: article,
          isAdmin: widget.isAdmin)));
  }

  void _navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleArticlesListView(
          isAdmin: true,
          showAdminTools: true)));
  }
}
