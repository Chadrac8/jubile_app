import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';

import '../models/blog_post.dart';
import '../models/blog_comment.dart';
import '../services/blog_service.dart';

/// Vue détaillée d'un article de blog
class BlogDetailView extends StatefulWidget {
  final BlogPost? post;

  const BlogDetailView({Key? key, this.post}) : super(key: key);

  @override
  State<BlogDetailView> createState() => _BlogDetailViewState();
}

class _BlogDetailViewState extends State<BlogDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlogService _blogService = BlogService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  
  BlogPost? _post;
  List<BlogComment> _comments = [];
  List<BlogPost> _relatedPosts = [];
  
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _showCommentForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _post = widget.post;
    if (_post != null) {
      _loadPostData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    if (_post?.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _blogService.getComments(_post!.id!),
        _blogService.getPublishedPosts(limit: 5), // Articles similaires
      ]);

      if (mounted) {
        setState(() {
          _comments = results[0] as List<BlogComment>;
          _relatedPosts = (results[1] as List<BlogPost>)
              .where((p) => p.id != _post!.id)
              .take(3)
              .toList();
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

  @override
  Widget build(BuildContext context) {
    if (_post == null) {
      return BasePage(
        title: 'Article',
        body: const Center(
          child: Text('Article non trouvé'),
        ),
      );
    }

    return BasePage(
      title: _post!.title,
      actions: [
        IconButton(
          icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
          onPressed: _toggleBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _sharePost,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy_link',
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Copier le lien'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.flag),
                title: Text('Signaler'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Article', icon: Icon(Icons.article)),
              Tab(
                text: 'Commentaires',
                icon: Badge(
                  label: Text(_comments.length.toString()),
                  child: Icon(Icons.comment),
                ),
              ),
              Tab(text: 'Similaires', icon: Icon(Icons.recommend)),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildArticleTab(),
                      _buildCommentsTab(),
                      _buildRelatedTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image en vedette
          if (_post!.featuredImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _post!.featuredImageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    "https://pixabay.com/get/g26526e9480fb2b4cadf1c97139d50203bb3bb94c9e11926789a5a21af1c717b2eeebc03f03e5f3dd2b05a900e18ca87e_1280.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.article, size: 64),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Métadonnées de l'article
          _buildPostMetadata(),
          
          const SizedBox(height: 20),
          
          // Titre
          Text(
            _post!.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Extrait
          if (_post!.excerpt.isNotEmpty)
            Text(
              _post!.excerpt,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Contenu
          Text(
            _post!.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Tags
          if (_post!.tags.isNotEmpty) _buildTags(),
          
          const SizedBox(height: 24),
          
          // Actions
          _buildActionButtons(),
          
          const SizedBox(height: 24),
          
          // Informations sur l'auteur
          _buildAuthorInfo(),
        ],
      ),
    );
  }

  Widget _buildPostMetadata() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _post!.authorPhotoUrl != null 
                      ? NetworkImage(_post!.authorPhotoUrl!) 
                      : null,
                  child: _post!.authorPhotoUrl == null 
                      ? Text(_post!.authorName.isNotEmpty ? _post!.authorName[0] : 'A')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post!.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(_post!.publishedAt ?? _post!.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(Icons.visibility, _post!.views.toString(), 'Vues'),
                _buildMetricItem(Icons.favorite, _post!.likes.toString(), 'Likes'),
                _buildMetricItem(Icons.comment, _post!.commentsCount.toString(), 'Commentaires'),
                _buildMetricItem(Icons.schedule, '\${_post!.estimatedReadingTime} min', 'Lecture'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _post!.tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              '#\$tag',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _toggleLike,
          icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
          label: Text(_isLiked ? 'Aimé' : 'Aimer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLiked ? Colors.red : null,
            foregroundColor: _isLiked ? Colors.white : null,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showCommentDialog(),
          icon: const Icon(Icons.comment),
          label: const Text('Commenter'),
        ),
        OutlinedButton.icon(
          onPressed: _sharePost,
          icon: const Icon(Icons.share),
          label: const Text('Partager'),
        ),
      ],
    );
  }

  Widget _buildAuthorInfo() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'À propos de l\'auteur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: _post!.authorPhotoUrl != null 
                      ? NetworkImage(_post!.authorPhotoUrl!) 
                      : null,
                  child: _post!.authorPhotoUrl == null 
                      ? Text(_post!.authorName.isNotEmpty ? _post!.authorName[0] : 'A')
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post!.authorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Membre de l\'équipe de rédaction',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        // Bouton pour ajouter un commentaire
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showCommentDialog,
            icon: const Icon(Icons.add_comment),
            label: const Text('Ajouter un commentaire'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        
        // Liste des commentaires
        Expanded(
          child: _comments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun commentaire pour le moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Soyez le premier à commenter !',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return _buildCommentItem(comment);
                  },
                ),
        ),
      ],
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (comment.likes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          comment.likes.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment.content,
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _likeComment(comment),
                  icon: const Icon(Icons.favorite_border, size: 16),
                  label: const Text('Aimer'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _replyToComment(comment),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Répondre'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedTab() {
    return _relatedPosts.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun article similaire trouvé'),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _relatedPosts.length,
            itemBuilder: (context, index) {
              final post = _relatedPosts[index];
              return _buildRelatedPostItem(post);
            },
          );
  }

  Widget _buildRelatedPostItem(BlogPost post) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
          ),
          child: post.featuredImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.featuredImageUrl!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.article),
        ),
        title: Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.excerpt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Par ${post.authorName} • ${post.views} vues',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToPost(post),
      ),
    );
  }

  // Actions
  void _toggleLike() async {
    if (_post?.id == null) return;
    
    final success = await _blogService.toggleLike(_post!.id!);
    if (success) {
      setState(() {
        _isLiked = !_isLiked;
        _post = _post!.copyWith(
          likes: _isLiked ? _post!.likes + 1 : _post!.likes - 1,
        );
      });
    }
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Article ajouté aux favoris' : 'Article retiré des favoris'),
      ),
    );
  }

  void _sharePost() {
    // Implémentation du partage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_link':
        Clipboard.setData(ClipboardData(text: 'https://churchflow.app/blog/${_post!.id}'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien copié dans le presse-papiers')),
        );
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un commentaire'),
        content: TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Écrivez votre commentaire ici...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _submitComment,
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty || _post?.id == null) return;

    final comment = BlogComment(
      postId: _post!.id!,
      authorId: 'current_user_id', // À remplacer par l'ID de l'utilisateur actuel
      authorName: 'Utilisateur actuel', // À remplacer par le nom de l'utilisateur actuel
      content: _commentController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final commentId = await _blogService.addComment(comment);
    if (commentId != null) {
      Navigator.of(context).pop();
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commentaire ajouté avec succès')),
      );
      _loadPostData(); // Recharger les commentaires
    }
  }

  void _likeComment(BlogComment comment) {
    // Implémentation du like de commentaire
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commentaire aimé')),
    );
  }

  void _replyToComment(BlogComment comment) {
    // Implémentation de la réponse à un commentaire
    _showCommentDialog();
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cet article'),
        content: const Text('Fonctionnalité de signalement à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Article signalé')),
              );
            },
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  void _navigateToPost(BlogPost post) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BlogDetailView(post: post),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}