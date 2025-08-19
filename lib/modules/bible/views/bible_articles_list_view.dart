import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bible_article.dart';
import '../../services/bible_article_service.dart';
import 'bible_article_detail_view.dart';
import 'bible_article_form_view.dart';

class BibleArticlesListView extends StatefulWidget {
  final bool isAdmin;
  final bool showAdminTools;

  const BibleArticlesListView({
    super.key,
    this.isAdmin = false,
    this.showAdminTools = false,
  });

  @override
  State<BibleArticlesListView> createState() => _BibleArticlesListViewState();
}

class _BibleArticlesListViewState extends State<BibleArticlesListView> {
  final BibleArticleService _articleService = BibleArticleService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<BibleArticle> _allArticles = [];
  List<BibleArticle> _filteredArticles = [];
  String _selectedCategory = 'Toutes';
  String _sortBy = 'recent';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    
    try {
      final articles = await _articleService.getArticles();
      setState(() {
        _allArticles = widget.showAdminTools 
            ? articles 
            : articles.where((a) => a.isPublished).toList();
        _filteredArticles = _allArticles;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<BibleArticle> filtered = _allArticles;

    // Filtrer par recherche
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((article) {
        return article.title.toLowerCase().contains(query) ||
               article.summary.toLowerCase().contains(query) ||
               article.content.toLowerCase().contains(query) ||
               article.author.toLowerCase().contains(query) ||
               article.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Filtrer par catégorie
    if (_selectedCategory != 'Toutes') {
      filtered = filtered.where((article) => article.category == _selectedCategory).toList();
    }

    // Trier
    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popular':
        filtered.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'alphabetical':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'reading_time':
        filtered.sort((a, b) => a.readingTimeMinutes.compareTo(b.readingTimeMinutes));
        break;
    }

    setState(() {
      _filteredArticles = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Articles bibliques',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (widget.showAdminTools)
            IconButton(
              onPressed: _navigateToCreateArticle,
              icon: const Icon(Icons.add),
              tooltip: 'Nouvel article'),
        ]),
      body: Column(
        children: [
          _buildSearchAndFilters(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildArticlesList(theme)),
        ]));
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            decoration: InputDecoration(
              hintText: 'Rechercher des articles...',
              prefixIcon: const Icon(Icons.search_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor)),
              filled: true,
              fillColor: theme.colorScheme.surface)),
          const SizedBox(height: 16),
          
          // Filtres
          Row(
            children: [
              // Catégorie
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: ['Toutes', ..._articleService.getAvailableCategories()]
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category, style: GoogleFonts.inter(fontSize: 14))))
                      .toList())),
              const SizedBox(width: 12),
              
              // Tri
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('Plus récents')),
                    DropdownMenuItem(value: 'popular', child: Text('Plus populaires')),
                    DropdownMenuItem(value: 'alphabetical', child: Text('Alphabétique')),
                    DropdownMenuItem(value: 'reading_time', child: Text('Temps de lecture')),
                  ])),
            ]),
        ]));
  }

  Widget _buildArticlesList(ThemeData theme) {
    if (_filteredArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: theme.hintColor),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Aucun article trouvé'
                  : 'Aucun article disponible',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: theme.hintColor)),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Essayez avec d\'autres mots-clés'
                  : 'Les articles apparaîtront ici',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.hintColor.withValues(alpha: 0.7))),
          ]));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredArticles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final article = _filteredArticles[index];
        return _buildArticleCard(article, theme);
      });
  }

  Widget _buildArticleCard(BibleArticle article, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToArticleDetail(article),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec catégorie et statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      article.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.primaryColor))),
                  const Spacer(),
                  if (widget.showAdminTools && !article.isPublished)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'Brouillon',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.warningColor))),
                  if (widget.showAdminTools)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleArticleAction(value, article),
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
                          value: article.isPublished ? 'unpublish' : 'publish',
                          child: Row(
                            children: [
                              Icon(
                                article.isPublished 
                                    ? Icons.visibility_off_outlined 
                                    : Icons.visibility_outlined,
                                size: 18),
                              const SizedBox(width: 8),
                              Text(article.isPublished ? 'Dépublier' : 'Publier'),
                            ])),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.errorColor),
                              const SizedBox(width: 8),
                              Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.errorColor)),
                            ])),
                      ]),
                ]),
              const SizedBox(height: 16),
              
              // Titre et résumé
              Text(
                article.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                article.summary,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              
              // Métadonnées
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    article.author,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.hintColor)),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${article.readingTimeMinutes} min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.hintColor)),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: theme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    '${article.viewCount}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.hintColor)),
                  const Spacer(),
                  Text(
                    _formatDate(article.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.hintColor)),
                ]),
              
              // Tags
              if (article.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: article.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: theme.textTheme.bodySmall?.color)))).toList()),
              ],
            ]))));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = difference.inDays ~/ 7;
      return 'Il y a ${weeks} semaine${weeks > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToArticleDetail(BibleArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleArticleDetailView(
          article: article,
          isAdmin: widget.isAdmin))).then((_) => _loadArticles()); // Recharger après retour
  }

  void _navigateToCreateArticle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BibleArticleFormView())).then((_) => _loadArticles()); // Recharger après création
  }

  void _handleArticleAction(String action, BibleArticle article) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BibleArticleFormView(article: article))).then((_) => _loadArticles());
        break;
      case 'publish':
      case 'unpublish':
        _togglePublishStatus(article);
        break;
      case 'delete':
        _showDeleteConfirmation(article);
        break;
    }
  }

  Future<void> _togglePublishStatus(BibleArticle article) async {
    try {
      final updatedArticle = article.copyWith(isPublished: !article.isPublished);
      await _articleService.updateArticle(updatedArticle);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedArticle.isPublished 
                ? 'Article publié avec succès'
                : 'Article dépublié avec succès')));
      
      _loadArticles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour')));
    }
  }

  void _showDeleteConfirmation(BibleArticle article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${article.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArticle(article);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.errorColor),
            child: const Text('Supprimer')),
        ]));
  }

  Future<void> _deleteArticle(BibleArticle article) async {
    try {
      await _articleService.deleteArticle(article.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article supprimé avec succès')));
      
      _loadArticles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')));
    }
  }
}
