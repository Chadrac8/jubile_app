import 'package:flutter/material.dart';
import '../models/blog_model.dart';
import '../services/blog_firebase_service.dart';
import '../widgets/blog_post_card.dart';
import '../widgets/blog_search_filter_bar.dart';
import 'blog_post_detail_page.dart';
import 'blog_post_form_page.dart';
import 'blog_categories_page.dart';
import '../auth/auth_service.dart';

class BlogHomePage extends StatefulWidget {
  const BlogHomePage({super.key});

  @override
  State<BlogHomePage> createState() => _BlogHomePageState();
}

class _BlogHomePageState extends State<BlogHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Filtres
  List<String> _selectedCategories = [];
  List<String> _selectedTags = [];
  String _searchQuery = '';
  BlogPostStatus? _selectedStatus;
  String? _selectedAuthor;
  
  // États
  bool _isLoading = false;
  List<BlogCategory> _availableCategories = [];
  List<String> _availableTags = [];
  bool _isAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _checkUserPermissions();
    _tabController = TabController(length: _isAdmin ? 2 : 1, vsync: this);
    _loadFilterOptions();
  }

  void _checkUserPermissions() {
    _isAdmin = AuthService.hasRole('admin') || 
               AuthService.hasRole('pastor') ||
               AuthService.hasRole('communication_manager') ||
               AuthService.hasPermission('blog_manage');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    setState(() => _isLoading = true);
    
    try {
      final categories = await BlogFirebaseService.getCategoriesStream().first;
      final tags = await BlogFirebaseService.getAllTags();
      
      setState(() {
        _availableCategories = categories;
        _availableTags = tags;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onFiltersChanged({
    List<String>? categories,
    List<String>? tags,
    BlogPostStatus? status,
    String? author,
  }) {
    setState(() {
      if (categories != null) _selectedCategories = categories;
      if (tags != null) _selectedTags = tags;
      if (status != null) _selectedStatus = status;
      if (author != null) _selectedAuthor = author;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedTags.clear();
      _searchQuery = '';
      _selectedStatus = null;
      _selectedAuthor = null;
    });
  }

  /// Vérifie si l'utilisateur peut créer des articles de blog
  bool _canCreatePost() {
    return AuthService.hasPermission('blog_create') || 
           AuthService.hasRole('admin') ||
           AuthService.hasRole('pastor') ||
           AuthService.hasRole('communication_manager');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
        bottom: _isAdmin
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.public), text: 'Articles publiés'),
                  Tab(icon: Icon(Icons.admin_panel_settings), text: 'Gestion'),
                ],
              )
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.article), text: 'Articles'),
                ],
              ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlogCategoriesPage(),
                  ),
                );
              },
              tooltip: 'Gérer les catégories',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFilterOptions,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _isAdmin
            ? [
                _buildPublicView(),
                _buildAdminView(),
              ]
            : [
                _buildPublicView(),
              ],
      ),
      floatingActionButton: _canCreatePost()
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlogPostFormPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Nouvel article',
            )
          : null,
    );
  }

  Widget _buildPublicView() {
    return Column(
      children: [
        // Barre de recherche et filtres
        BlogSearchFilterBar(
          onSearchChanged: _onSearchChanged,
          onFiltersChanged: _onFiltersChanged,
          availableCategories: _availableCategories,
          availableTags: _availableTags,
          selectedCategories: _selectedCategories,
          selectedTags: _selectedTags,
          searchQuery: _searchQuery,
          showStatusFilter: false, // Masquer le filtre de statut pour le public
          onClearFilters: _clearFilters,
        ),
        
        // Liste des articles
        Expanded(
          child: _buildPostsList(isPublicView: true),
        ),
      ],
    );
  }

  Widget _buildAdminView() {
    return Column(
      children: [
        // Barre de recherche et filtres pour admin
        BlogSearchFilterBar(
          onSearchChanged: _onSearchChanged,
          onFiltersChanged: _onFiltersChanged,
          availableCategories: _availableCategories,
          availableTags: _availableTags,
          selectedCategories: _selectedCategories,
          selectedTags: _selectedTags,
          searchQuery: _searchQuery,
          selectedStatus: _selectedStatus,
          showStatusFilter: true,
          onClearFilters: _clearFilters,
        ),
        
        // Statistiques rapides
        _buildQuickStats(),
        
        // Liste des articles
        Expanded(
          child: _buildPostsList(isPublicView: false),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: BlogFirebaseService.getBlogStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Publiés',
                stats['posts_published']?.toString() ?? '0',
                Colors.green,
                Icons.publish,
              ),
              _buildStatCard(
                'Brouillons',
                stats['posts_draft']?.toString() ?? '0',
                Colors.orange,
                Icons.drafts,
              ),
              _buildStatCard(
                'Commentaires',
                stats['total_comments']?.toString() ?? '0',
                Colors.blue,
                Icons.comment,
              ),
              _buildStatCard(
                'Catégories',
                stats['total_categories']?.toString() ?? '0',
                Colors.purple,
                Icons.category,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList({required bool isPublicView}) {
    // Déterminer les statuts à afficher
    List<BlogPostStatus>? statuses;
    if (isPublicView) {
      statuses = [BlogPostStatus.published];
    } else if (_selectedStatus != null) {
      statuses = [_selectedStatus!];
    }

    return StreamBuilder<List<BlogPost>>(
      stream: isPublicView
          ? BlogFirebaseService.getPublishedPostsStream(
              categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
              tags: _selectedTags.isNotEmpty ? _selectedTags : null,
              searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
              limit: 50,
            )
          : BlogFirebaseService.getPostsStream(
              statuses: statuses,
              categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
              tags: _selectedTags.isNotEmpty ? _selectedTags : null,
              searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
              authorId: _selectedAuthor,
              limit: 50,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadFilterOptions,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _buildEmptyState(isPublicView);
        }

        return RefreshIndicator(
          onRefresh: _loadFilterOptions,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return BlogPostCard(
                post: post,
                isAdminView: !isPublicView,
                onTap: () => _openPostDetail(post),
                onEdit: !isPublicView ? () => _editPost(post) : null,
                onDelete: !isPublicView ? () => _deletePost(post) : null,
                onToggleFeatured: !isPublicView ? () => _toggleFeatured(post) : null,
                onPublish: !isPublicView && post.status == BlogPostStatus.draft
                    ? () => _publishPost(post)
                    : null,
                onArchive: !isPublicView && post.status == BlogPostStatus.published
                    ? () => _archivePost(post)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isPublicView) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPublicView ? Icons.article_outlined : Icons.create_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isPublicView 
                ? 'Aucun article publié'
                : 'Aucun article trouvé',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPublicView
                ? 'Les articles apparaîtront ici une fois publiés.'
                : 'Créez votre premier article ou ajustez vos filtres.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (!isPublicView) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlogPostFormPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un article'),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Effacer les filtres'),
          ),
        ],
      ),
    );
  }

  void _openPostDetail(BlogPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogPostDetailPage(postId: post.id),
      ),
    );
  }

  void _editPost(BlogPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogPostFormPage(post: post),
      ),
    ).then((_) => _loadFilterOptions());
  }

  Future<void> _deletePost(BlogPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${post.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BlogFirebaseService.deletePost(post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleFeatured(BlogPost post) async {
    try {
      await BlogFirebaseService.toggleFeaturedPost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              post.isFeatured 
                  ? 'Article retiré des articles en vedette' 
                  : 'Article mis en vedette',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _publishPost(BlogPost post) async {
    try {
      await BlogFirebaseService.publishPost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article publié')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _archivePost(BlogPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver l\'article'),
        content: Text('Archiver "${post.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BlogFirebaseService.archivePost(post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article archivé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}