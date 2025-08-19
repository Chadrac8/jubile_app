import 'package:flutter/material.dart';
import '../models/blog_post.dart';
import '../models/blog_category.dart';
import '../services/blog_service.dart';
import '../../../shared/widgets/base_page.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../extensions/datetime_extensions.dart';

/// Vue de formulaire pour créer/modifier un article de blog
class BlogFormView extends StatefulWidget {
  final BlogPost? post;
  final bool isEdit;

  const BlogFormView({Key? key, this.post, this.isEdit = false}) : super(key: key);

  @override
  State<BlogFormView> createState() => _BlogFormViewState();
}

class _BlogFormViewState extends State<BlogFormView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BlogService _blogService = BlogService();
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs de texte
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _metaTitleController = TextEditingController();
  final _metaDescriptionController = TextEditingController();
  
  // Variables d'état
  List<BlogCategory> _categories = [];
  List<String> _selectedCategories = [];
  List<String> _tags = [];
  String? _featuredImageUrl;
  BlogPostStatus _status = BlogPostStatus.draft;
  DateTime? _scheduledDate;
  bool _allowComments = true;
  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCategories();
    
    if (widget.post != null) {
      _populateFields();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.getActiveCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  void _populateFields() {
    final post = widget.post!;
    _titleController.text = post.title;
    _excerptController.text = post.excerpt;
    _contentController.text = post.content;
    _selectedCategories = List.from(post.categories);
    _tags = List.from(post.tags);
    _tagsController.text = post.tags.join(', ');
    _featuredImageUrl = post.featuredImageUrl;
    _status = post.status;
    _scheduledDate = post.scheduledAt;
    _allowComments = post.allowComments;
    _isFeatured = post.isFeatured;
    
    // SEO
    _metaTitleController.text = post.seoData['title'] ?? '';
    _metaDescriptionController.text = post.seoData['description'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: widget.isEdit ? 'Modifier l\'article' : 'Nouvel article',
      actions: [
        if (widget.isEdit)
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _previewPost,
          ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _savePost,
        ),
      ],
      body: Column(
        children: [
          // Barre d'actions rapides
          _buildQuickActions(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Contenu', icon: Icon(Icons.edit)),
              Tab(text: 'Catégories', icon: Icon(Icons.category)),
              Tab(text: 'Apparence', icon: Icon(Icons.image)),
              Tab(text: 'Paramètres', icon: Icon(Icons.settings)),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentTab(),
                  _buildCategoriesTab(),
                  _buildAppearanceTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusLabel(_status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Actions
          if (_status == BlogPostStatus.draft)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _quickPublish(),
              icon: const Icon(Icons.publish, size: 16),
              label: const Text('Publier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          
          const SizedBox(width: 8),
          
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _saveDraft,
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre de l\'article *',
              hintText: 'Saisissez un titre accrocheur...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              if (value.length < 10) {
                return 'Le titre doit faire au moins 10 caractères';
              }
              return null;
            },
            onChanged: (_) => _generateSlugAndExcerpt(),
          ),
          
          const SizedBox(height: 16),
          
          // Extrait
          TextFormField(
            controller: _excerptController,
            decoration: const InputDecoration(
              labelText: 'Extrait',
              hintText: 'Résumé court de l\'article...',
              border: OutlineInputBorder(),
              helperText: 'Affiché dans les listes d\'articles (recommandé: 150-160 caractères)',
            ),
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 200) {
                return 'L\'extrait ne doit pas dépasser 200 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Contenu principal
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Contenu de l\'article *',
              hintText: 'Rédigez votre article ici...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 15,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le contenu est obligatoire';
              }
              if (value.length < 100) {
                return 'L\'article doit faire au moins 100 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Tags
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'foi, église, communauté, prière...',
              border: OutlineInputBorder(),
              helperText: 'Séparez les tags par des virgules',
            ),
            onChanged: (value) {
              _tags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Informations sur l'article
          _buildArticleInfo(),
        ],
      ),
    );
  }

  Widget _buildArticleInfo() {
    final wordCount = _contentController.text.split(' ').where((word) => word.isNotEmpty).length;
    final readingTime = (wordCount / 200).ceil();
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations sur l\'article',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Mots', wordCount.toString()),
                _buildInfoItem('Lecture', '\$readingTime min'),
                _buildInfoItem('Caractères', _contentController.text.length.toString()),
                _buildInfoItem('Tags', _tags.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catégories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addNewCategory,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle catégorie'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_isLoadingCategories)
            const Center(child: CircularProgressIndicator())
          else if (_categories.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune catégorie disponible'),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) => FilterChip(
                label: Text(category.name ?? 'Sans nom'),
                selected: _selectedCategories.contains(category.name ?? ''),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category.name ?? '');
                    } else {
                      _selectedCategories.remove(category.name ?? '');
                    }
                  });
                },
                avatar: category.colorCode != null && category.colorCode!.isNotEmpty
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse(category.colorCode!.substring(1, 7), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              )).toList(),
            ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Catégories sélectionnées',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          
          const SizedBox(height: 8),
          
          if (_selectedCategories.isEmpty)
            const Text(
              'Aucune catégorie sélectionnée',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _selectedCategories.map((category) => Chip(
                label: Text(category),
                onDeleted: () {
                  setState(() {
                    _selectedCategories.remove(category);
                  });
                },
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image en vedette',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          
          // Image en vedette
          CustomCard(
            child: Column(
              children: [
                if (_featuredImageUrl != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: Image.network(
                          _featuredImageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _featuredImageUrl = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _selectFeaturedImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Ajouter une image'),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Options d'image
                if (_featuredImageUrl == null)
                  Column(
                    children: [
                      const Text('ou'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _generateImageFromTitle,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Générer depuis le titre'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // SEO
          const Text(
            'Optimisation pour les moteurs de recherche',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _metaTitleController,
            decoration: const InputDecoration(
              labelText: 'Titre SEO',
              hintText: 'Titre optimisé pour Google (60 caractères max)',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.length > 60) {
                return 'Le titre SEO ne doit pas dépasser 60 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _metaDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description SEO',
              hintText: 'Description pour les résultats de recherche (160 caractères max)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 160) {
                return 'La description SEO ne doit pas dépasser 160 caractères';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Publication',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          
          // Statut
          DropdownButtonFormField<BlogPostStatus>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Statut',
              border: OutlineInputBorder(),
            ),
            items: BlogPostStatus.values.map((status) => DropdownMenuItem(
              value: status,
              child: Text(_getStatusLabel(status)),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _status = value;
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Programmation
          if (_status == BlogPostStatus.scheduled) ...[
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Date de publication'),
              subtitle: Text(_scheduledDate != null 
                  ? _formatDate(_scheduledDate!) 
                  : 'Aucune date sélectionnée'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectScheduledDate,
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Options
          const Text(
            'Options',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Autoriser les commentaires'),
            subtitle: const Text('Les lecteurs peuvent commenter cet article'),
            value: _allowComments,
            onChanged: (value) {
              setState(() {
                _allowComments = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Article en vedette'),
            subtitle: const Text('Mettre en avant dans la liste des articles'),
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Actions avancées
          if (widget.isEdit) ...[
            const Text(
              'Actions avancées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Dupliquer l\'article'),
              subtitle: const Text('Créer une copie en brouillon'),
              onTap: _duplicatePost,
            ),
            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer l\'article', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Action irréversible'),
              onTap: _confirmDeletePost,
            ),
          ],
        ],
      ),
    );
  }

  // Actions
  void _generateSlugAndExcerpt() {
    if (_excerptController.text.isEmpty && _titleController.text.isNotEmpty) {
      // Générer automatiquement un extrait depuis le titre
      setState(() {
        _excerptController.text = '${_titleController.text.length > 100 
            ? '${_titleController.text.substring(0, 100)}...' 
            : _titleController.text}';
      });
    }
  }

  void _addNewCategory() {
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

  void _selectFeaturedImage() {
    // Pour cette démo, on génère une image aléatoirement
    final imageUrl = "https://images.unsplash.com/photo-1604882737206-8a000c03d8fe?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTk0NzB8&ixlib=rb-4.1.0&q=80&w=1080";
    
    setState(() {
      _featuredImageUrl = imageUrl;
    });
  }

  void _generateImageFromTitle() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord saisir un titre')),
      );
      return;
    }
    
    final imageUrl = "https://images.unsplash.com/photo-1495552665515-46e119a10545?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NTA0MTk0NzB8&ixlib=rb-4.1.0&q=80&w=1080";
    
    setState(() {
      _featuredImageUrl = imageUrl;
    });
  }

  void _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
      );
      
      if (time != null) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _quickPublish() async {
    setState(() {
      _status = BlogPostStatus.published;
    });
    await _savePost();
  }

  void _saveDraft() async {
    setState(() {
      _status = BlogPostStatus.draft;
    });
    await _savePost();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez corriger les erreurs dans le formulaire')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      
      final post = BlogPost(
        id: widget.post?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        excerpt: _excerptController.text.trim().isNotEmpty 
            ? _excerptController.text.trim()
            : _generateExcerptFromContent(),
        authorId: 'current_user_id', // À remplacer
        authorName: 'Auteur actuel', // À remplacer
        categories: _selectedCategories,
        tags: _tags,
        featuredImageUrl: _featuredImageUrl,
        status: _status,
        createdAt: widget.post?.createdAt ?? now,
        updatedAt: now,
        publishedAt: _status == BlogPostStatus.published ? now : null,
        scheduledAt: _scheduledDate,
        allowComments: _allowComments,
        isFeatured: _isFeatured,
        seoData: {
          'title': _metaTitleController.text.trim(),
          'description': _metaDescriptionController.text.trim(),
        },
      );

      bool success;
      if (widget.isEdit) {
        await _blogService.update(post.id!, post);
        success = true;
      } else {
        final result = await _blogService.create(post);
        success = result.isNotEmpty;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Article modifié avec succès' : 'Article créé avec succès'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        throw Exception('Erreur lors de la sauvegarde');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: \$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateExcerptFromContent() {
    final words = _contentController.text.trim().split(' ');
    if (words.length > 30) {
      return '${words.take(30).join(' ')}...';
    }
    return _contentController.text.trim();
  }

  void _previewPost() {
    if (widget.post != null) {
      Navigator.of(context).pushNamed('/blog/detail', arguments: widget.post);
    }
  }

  void _duplicatePost() async {
    if (widget.post?.id == null) return;
    
    final newId = await _blogService.duplicatePost(widget.post!.id!);
    if (newId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article dupliqué avec succès')),
      );
      Navigator.of(context).pop();
    }
  }

  void _confirmDeletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cet article ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (widget.post?.id != null) {
                try {
                  await _blogService.delete(widget.post!.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Article supprimé avec succès')),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
    return date.shortDateTime;
  }
}