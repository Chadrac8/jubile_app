import 'package:flutter/material.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../models/blog_post.dart';
import '../models/blog_comment.dart';
import '../models/blog_category.dart';
import '../services/blog_service.dart';

/// Vue admin du module Blog
class BlogAdminView extends StatefulWidget {
  const BlogAdminView({Key? key}) : super(key: key);

  @override
  State<BlogAdminView> createState() => _BlogAdminViewState();
}

class _BlogAdminViewState extends State<BlogAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlogService _blogService = BlogService();
  
  List<BlogPost> _allPosts = [];
  List<BlogComment> _pendingComments = [];
  List<BlogCategory> _categories = [];
  Map<String, dynamic> _statistics = {};
  
  bool _isLoading = true;
  String _searchQuery = '';
  BlogPostStatus? _selectedStatus;

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
        _blogService.getAll(),
        _blogService.getPendingComments(),
        _blogService.getActiveCategories(),
        _blogService.getBlogStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _allPosts = results[0] as List<BlogPost>;
          _pendingComments = results[1] as List<BlogComment>;
          _categories = results[2] as List<BlogCategory>;
          _statistics = results[3] as Map<String, dynamic>;
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

  List<BlogPost> get _filteredPosts {
    var posts = _allPosts;
    
    if (_selectedStatus != null) {
      posts = posts.where((post) => post.status == _selectedStatus).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      posts = posts.where((post) => 
        post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.authorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        post.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Gestion du Blog',
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToForm(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
      ],
      body: Column(
        children: [
          // Statistiques rapides
          _buildQuickStats(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                text: 'Articles',
                icon: Badge(
                  label: Text(_allPosts.length.toString()),
                  child: const Icon(Icons.article),
                ),
              ),
              Tab(
                text: 'Commentaires',
                icon: Badge(
                  label: Text(_pendingComments.length.toString()),
                  child: const Icon(Icons.comment),
                ),
              ),
              Tab(
                text: 'Catégories',
                icon: Badge(
                  label: Text(_categories.length.toString()),
                  child: const Icon(Icons.category),
                ),
              ),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsTab(),
                      _buildCommentsTab(),
                      _buildCategoriesTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_statistics.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip('Total', _statistics['total'] ?? 0, Colors.blue),
            _buildStatChip('Publiés', _statistics['published'] ?? 0, Colors.green),
            _buildStatChip('Brouillons', _statistics['drafts'] ?? 0, Colors.orange),
            _buildStatChip('Programmés', _statistics['scheduled'] ?? 0, Colors.purple),
            _buildStatChip('Commentaires', _statistics['pendingComments'] ?? 0, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return Column(
      children: [
        // Filtres
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher des articles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<BlogPostStatus>(
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedStatus,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tous les statuts'),
                        ),
                        ...BlogPostStatus.values.map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusLabel(status)),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedStatus = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Liste des articles
        Expanded(
          child: _filteredPosts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucun article trouvé'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = _filteredPosts[index];
                    return _buildPostItem(post);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPostItem(BlogPost post) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _getStatusColor(post.status).withOpacity(0.1),
          ),
          child: Icon(
            _getStatusIcon(post.status),
            color: _getStatusColor(post.status),
          ),
        ),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Par ${post.authorName}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(post.status),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${post.views} vues • ${post.likes} likes',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (action) => _handlePostAction(action, post),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('Voir'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Modifier'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (post.status == BlogPostStatus.draft)
              const PopupMenuItem(
                value: 'publish',
                child: ListTile(
                  leading: Icon(Icons.publish),
                  title: Text('Publier'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (post.status == BlogPostStatus.published)
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archiver'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('Dupliquer'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToPost(post),
      ),
    );
  }

  Widget _buildCommentsTab() {
    return _pendingComments.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun commentaire en attente'),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingComments.length,
            itemBuilder: (context, index) {
              final comment = _pendingComments[index];
              return _buildCommentItem(comment);
            },
          );
  }

  Widget _buildCommentItem(BlogComment comment) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.authorPhotoUrl != null 
                      ? NetworkImage(comment.authorPhotoUrl!) 
                      : null,
                  child: comment.authorPhotoUrl == null 
                      ? Text(comment.authorName.isNotEmpty ? comment.authorName[0] : 'A')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    comment.statusLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(comment.content),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _rejectComment(comment),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rejeter'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveComment(comment),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approuver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catégories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _categories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune catégorie'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _buildCategoryItem(category);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(BlogCategory category) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.colorCode != null 
                ? Color(int.parse(category.colorCode!.substring(1, 7), radix: 16) + 0xFF000000)
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.category,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${category.postCount} articles'),
        trailing: Switch(
          value: category.isActive,
          onChanged: (value) => _toggleCategory(category, value),
        ),
      ),
    );
  }

  // Actions
  void _navigateToForm([BlogPost? post]) {
    Navigator.of(context).pushNamed(
      '/blog/form',
      arguments: post,
    ).then((_) => _loadData());
  }

  void _navigateToPost(BlogPost post) {
    Navigator.of(context).pushNamed(
      '/blog/detail',
      arguments: post,
    );
  }

  void _handlePostAction(String action, BlogPost post) async {
    switch (action) {
      case 'view':
        _navigateToPost(post);
        break;
      case 'edit':
        _navigateToForm(post);
        break;
      case 'publish':
        final success = await _blogService.publishPost(post.id!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article publié avec succès')),
          );
          _loadData();
        }
        break;
      case 'archive':
        final success = await _blogService.archivePost(post.id!);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article archivé avec succès')),
          );
          _loadData();
        }
        break;
      case 'duplicate':
        final newId = await _blogService.duplicatePost(post.id!);
        if (newId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article dupliqué avec succès')),
          );
          _loadData();
        }
        break;
      case 'delete':
        _confirmDelete(post);
        break;
    }
  }

  void _confirmDelete(BlogPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'article "${post.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _blogService.delete(post.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article supprimé avec succès')),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de la suppression: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _approveComment(BlogComment comment) async {
    final success = await _blogService.approveComment(comment.id!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire approuvé')),
      );
      _loadData();
    }
  }

  void _rejectComment(BlogComment comment) async {
    final success = await _blogService.rejectComment(comment.id!);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire rejeté')),
      );
      _loadData();
    }
  }

  void _addCategory() {
    // Logique pour ajouter une catégorie
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _toggleCategory(BlogCategory category, bool isActive) {
    // Logique pour activer/désactiver une catégorie
  }

  Color _getStatusColor(BlogPostStatus status) {
    switch (status) {
      case BlogPostStatus.draft:
        return Colors.grey;
      case BlogPostStatus.published:
        return Colors.green;
      case BlogPostStatus.scheduled:
        return Colors.blue;
      case BlogPostStatus.archived:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(BlogPostStatus status) {
    switch (status) {
      case BlogPostStatus.draft:
        return Icons.edit;
      case BlogPostStatus.published:
        return Icons.public;
      case BlogPostStatus.scheduled:
        return Icons.schedule;
      case BlogPostStatus.archived:
        return Icons.archive;
    }
  }

  String _getStatusLabel(BlogPostStatus status) {
    switch (status) {
      case BlogPostStatus.draft:
        return 'Brouillon';
      case BlogPostStatus.published:
        return 'Publié';
      case BlogPostStatus.scheduled:
        return 'Programmé';
      case BlogPostStatus.archived:
        return 'Archivé';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}