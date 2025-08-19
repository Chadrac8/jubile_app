import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/blog_model.dart';
import '../services/blog_firebase_service.dart';
import '../widgets/blog_comments_section.dart';
import '../widgets/blog_post_actions.dart';
import '../widgets/blog_post_metadata.dart';
import '../widgets/blog_related_posts.dart';
import 'blog_post_form_page.dart';


class BlogPostDetailPage extends StatefulWidget {
  final String postId;

  const BlogPostDetailPage({
    super.key,
    required this.postId,
  });

  @override
  State<BlogPostDetailPage> createState() => _BlogPostDetailPageState();
}

class _BlogPostDetailPageState extends State<BlogPostDetailPage> {
  BlogPost? _post;
  bool _isLoading = true;
  bool _hasLiked = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPost();
    _recordView();
    _checkIfLiked();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final post = await BlogFirebaseService.getPost(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _recordView() async {
    try {
      await BlogFirebaseService.recordPostView(widget.postId);
    } catch (e) {
      // Ignore les erreurs de vue - non critiques
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final hasLiked = await BlogFirebaseService.hasUserLikedPost(widget.postId);
      setState(() => _hasLiked = hasLiked);
    } catch (e) {
      // Ignore les erreurs de like check
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Article non trouvé')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Article non trouvé ou supprimé'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostHeader(),
                _buildPostContent(),
                _buildPostActions(),
                if (_post!.allowComments) _buildCommentsSection(),
                _buildRelatedPosts(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: _post!.featuredImageUrl != null ? 300 : 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _post!.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: _post!.featuredImageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _post!.featuredImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Partager'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'copy_link',
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Copier le lien'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_canEditPost())
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Modifier'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métadonnées de l'article
          BlogPostMetadata(post: _post!),
          
          const SizedBox(height: 16),
          
          // Excerpt si disponible
          if (_post!.excerpt.isNotEmpty) ...[
            Text(
              _post!.excerpt,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contenu principal
          SelectableText(
            _post!.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Images additionnelles
          if (_post!.imageUrls.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Images',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildImageGallery(),
            const SizedBox(height: 16),
          ],
          
          // Tags
          if (_post!.tags.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _post!.tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                side: BorderSide(color: Theme.of(context).primaryColor),
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _post!.imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = _post!.imageUrls[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showImageDialog(imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlogPostActions(
        post: _post!,
        hasLiked: _hasLiked,
        onLike: _handleLike,
        onShare: _handleShare,
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Commentaires',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          BlogCommentsSection(postId: _post!.id),
        ],
      ),
    );
  }

  Widget _buildRelatedPosts() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Articles similaires',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          BlogRelatedPosts(
            currentPost: _post!,
            onPostTap: (post) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BlogPostDetailPage(postId: post.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _canEditPost() {
    // Vérifier si l'utilisateur peut modifier cet article
    // Pour l'instant, on considère que tout utilisateur connecté peut modifier
    return true;
  }

  Future<void> _handleLike() async {
    try {
      await BlogFirebaseService.likePost(_post!.id);
      setState(() => _hasLiked = !_hasLiked);
      
      // Recharger l'article pour avoir le nouveau compteur de likes
      await _loadPost();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _handleShare() {
    // Fonctionnalité de partage basique
    final text = '${_post!.title}\n\nLisez cet article sur notre blog.';
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié dans le presse-papiers')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _handleShare();
        break;
      case 'copy_link':
        Clipboard.setData(ClipboardData(text: 'Article: ${_post!.title}'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien copié')),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlogPostFormPage(post: _post),
          ),
        ).then((_) => _loadPost());
        break;
    }
  }
}