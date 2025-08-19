import 'package:flutter/material.dart';
import '../models/blog_post.dart';
import '../models/blog_category.dart';
import '../services/blog_service.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../extensions/datetime_extensions.dart';

/// Vue membre du module Blog
class BlogMemberView extends StatefulWidget {
  const BlogMemberView({Key? key}) : super(key: key);

  @override
  State<BlogMemberView> createState() => _BlogMemberViewState();
}

class _BlogMemberViewState extends State<BlogMemberView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlogService _blogService = BlogService();
  
  List<BlogPost> _recentPosts = [];
  List<BlogPost> _featuredPosts = [];
  List<BlogPost> _allPosts = [];
  List<BlogCategory> _categories = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _blogService.getRecentPosts(limit: 10),
        _blogService.getFeaturedPosts(limit: 5),
        _blogService.getPublishedPosts(),
        _blogService.getActiveCategories(),
      ]);

      if (mounted) {
        setState(() {
          _recentPosts = results[0] as List<BlogPost>;
          _featuredPosts = results[1] as List<BlogPost>;
          _allPosts = results[2] as List<BlogPost>;
          _categories = results[3] as List<BlogCategory>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: \$e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  List<BlogPost> get _filteredPosts {
    var posts = _allPosts;
    
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      posts = posts.where((post) => post.categories.contains(_selectedCategory)).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      posts = posts.where((post) => 
        post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Blog',
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(),
        ),
      ],
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Récents', icon: Icon(Icons.schedule)),
              Tab(text: 'À la une', icon: Icon(Icons.star)),
              Tab(text: 'Tous', icon: Icon(Icons.library_books)),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsList(_recentPosts),
                      _buildPostsList(_featuredPosts),
                      _buildPostsList(_filteredPosts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Champ de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher des articles...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: 12),
          
          // Filtre par catégorie
          if (_categories.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Toutes'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) => _onCategoryChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map((category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name ?? 'Sans nom'),
                      selected: _selectedCategory == category.name,
                      onSelected: (selected) => _onCategoryChanged(
                        selected ? category.name : null,
                      ),
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsList(List<BlogPost> posts) {
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun article trouvé', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(post);
        },
      ),
    );
  }

  Widget _buildPostCard(BlogPost post) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToPost(post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image en vedette
            if (post.featuredImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  post.featuredImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(
                      "https://images.unsplash.com/photo-1579215176023-00341ea5ea67?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTk0Mzl8&ixlib=rb-4.1.0&q=80&w=1080",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.article, size: 64),
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En vedette
                  if (post.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'À LA UNE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  
                  if (post.isFeatured) const SizedBox(height: 8),
                  
                  // Titre
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Extrait
                  Text(
                    post.excerpt,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Métadonnées
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: post.authorPhotoUrl != null 
                            ? NetworkImage(post.authorPhotoUrl!) 
                            : null,
                        child: post.authorPhotoUrl == null 
                            ? Text(post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'A')
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDate(post.publishedAt ?? post.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.views.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '\${post.estimatedReadingTime} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Tags
                  if (post.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: post.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#\$tag',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPost(BlogPost post) {
    // Incrémenter les vues
    _blogService.incrementViews(post.id!);
    
    Navigator.of(context).pushNamed(
      '/blog/detail',
      arguments: post,
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recherche avancée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Mots-clés',
                hintText: 'Rechercher dans le titre et le contenu',
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Catégorie'),
              value: _selectedCategory,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Toutes les catégories'),
                ),
                ..._categories.map((cat) => DropdownMenuItem(
                  value: cat.name,
                  child: Text(cat.name),
                )),
              ],
              onChanged: _onCategoryChanged,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.relativeDate;
  }
}