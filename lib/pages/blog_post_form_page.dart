import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/blog_model.dart';
import '../services/blog_firebase_service.dart';

import '../widgets/blog_post_preview_dialog.dart';

class BlogPostFormPage extends StatefulWidget {
  final BlogPost? post;

  const BlogPostFormPage({super.key, this.post});

  @override
  State<BlogPostFormPage> createState() => _BlogPostFormPageState();
}

class _BlogPostFormPageState extends State<BlogPostFormPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Contrôleurs de texte
  final _titleController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _metaTitleController = TextEditingController();
  final _metaDescriptionController = TextEditingController();
  
  // État du formulaire
  List<String> _selectedCategories = [];
  List<String> _availableCategories = [];
  String? _featuredImageUrl;
  List<String> _additionalImages = [];
  BlogPostStatus _selectedStatus = BlogPostStatus.draft;
  bool _allowComments = true;
  bool _isFeatured = false;
  DateTime? _scheduledDate;
  
  // État de l'interface
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCategories();
    _initializeForm();
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

  void _initializeForm() {
    if (widget.post != null) {
      final post = widget.post!;
      _titleController.text = post.title;
      _excerptController.text = post.excerpt;
      _contentController.text = post.content;
      _tagsController.text = post.tags.join(', ');
      _selectedCategories = List<String>.from(post.categories);
      _featuredImageUrl = post.featuredImageUrl;
      _additionalImages = List<String>.from(post.imageUrls);
      _selectedStatus = post.status;
      _allowComments = post.allowComments;
      _isFeatured = post.isFeatured;
      _scheduledDate = post.scheduledAt;
      
      // SEO
      _metaTitleController.text = post.seoData['metaTitle'] ?? '';
      _metaDescriptionController.text = post.seoData['metaDescription'] ?? '';
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final categories = await BlogFirebaseService.getCategoriesStream().first;
      setState(() {
        _availableCategories = categories.map((c) => c.name).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des catégories: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Nouvel article' : 'Modifier l\'article'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Contenu'),
            Tab(icon: Icon(Icons.image), text: 'Médias'),
            Tab(icon: Icon(Icons.settings), text: 'Options'),
            Tab(icon: Icon(Icons.search), text: 'SEO'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _previewPost,
            icon: const Icon(Icons.preview),
          ),
          IconButton(
            onPressed: _isSaving ? null : _savePost,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentTab(),
                  _buildMediaTab(),
                  _buildOptionsTab(),
                  _buildSeoTab(),
                ],
              ),
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
              labelText: 'Titre *',
              hintText: 'Entrez le titre de votre article',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              return null;
            },
            maxLines: null,
          ),
          
          const SizedBox(height: 16),
          
          // Résumé
          TextFormField(
            controller: _excerptController,
            decoration: const InputDecoration(
              labelText: 'Résumé',
              hintText: 'Bref résumé de l\'article (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Contenu
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Contenu *',
              hintText: 'Rédigez votre article ici...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le contenu est obligatoire';
              }
              return null;
            },
            maxLines: 20,
            minLines: 10,
          ),
          
          const SizedBox(height: 16),
          
          // Catégories
          Text(
            'Catégories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_availableCategories.isEmpty)
            const Text('Aucune catégorie disponible')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Tags
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'Séparez les tags par des virgules',
              border: OutlineInputBorder(),
              helperText: 'Ex: actualités, événement, communauté',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image en vedette
          Text(
            'Image en vedette',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildFeaturedImageSection(),
          
          const SizedBox(height: 24),
          
          // Images additionnelles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Images additionnelles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _addAdditionalImage,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAdditionalImagesSection(),
        ],
      ),
    );
  }

  Widget _buildFeaturedImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: _featuredImageUrl != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _featuredImageUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, size: 64),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => setState(() => _featuredImageUrl = null),
                    icon: const Icon(Icons.delete),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _selectFeaturedImage,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Ajouter une image en vedette'),
                ],
              ),
            ),
    );
  }

  Widget _buildAdditionalImagesSection() {
    if (_additionalImages.isEmpty) {
      return Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: const Center(
          child: Text('Aucune image additionnelle'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _additionalImages.length,
      itemBuilder: (context, index) {
        final imageUrl = _additionalImages[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeAdditionalImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          Text(
            'Statut de publication',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BlogPostStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: BlogPostStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value!);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Date de programmation
          if (_selectedStatus == BlogPostStatus.scheduled) ...[
            Text(
              'Date de publication',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(_scheduledDate != null 
                  ? 'Publier le ${_formatDate(_scheduledDate!)}'
                  : 'Sélectionner une date'),
              trailing: const Icon(Icons.date_range),
              onTap: _selectScheduledDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Options
          SwitchListTile(
            title: const Text('Autoriser les commentaires'),
            subtitle: const Text('Les lecteurs peuvent commenter cet article'),
            value: _allowComments,
            onChanged: (value) => setState(() => _allowComments = value),
          ),
          
          SwitchListTile(
            title: const Text('Article en vedette'),
            subtitle: const Text('Mettre en avant cet article'),
            value: _isFeatured,
            onChanged: (value) => setState(() => _isFeatured = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSeoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimisation pour les moteurs de recherche',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Méta titre
          TextFormField(
            controller: _metaTitleController,
            decoration: const InputDecoration(
              labelText: 'Titre SEO',
              hintText: 'Titre optimisé pour les moteurs de recherche',
              border: OutlineInputBorder(),
              helperText: 'Recommandé: 50-60 caractères',
            ),
            maxLength: 60,
          ),
          
          const SizedBox(height: 16),
          
          // Méta description
          TextFormField(
            controller: _metaDescriptionController,
            decoration: const InputDecoration(
              labelText: 'Description SEO',
              hintText: 'Description pour les moteurs de recherche',
              border: OutlineInputBorder(),
              helperText: 'Recommandé: 150-160 caractères',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 160,
          ),
          
          const SizedBox(height: 16),
          
          // Aperçu SEO
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aperçu dans les résultats de recherche',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _metaTitleController.text.isNotEmpty 
                        ? _metaTitleController.text 
                        : _titleController.text,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _metaDescriptionController.text.isNotEmpty
                        ? _metaDescriptionController.text
                        : _excerptController.text.isNotEmpty
                            ? _excerptController.text
                            : 'Aucune description disponible',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFeaturedImage() async {
    try {
      final imageUrl = await "https://images.unsplash.com/photo-1652960321814-dd8547e17187?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDk3MTE5ODZ8&ixlib=rb-4.1.0&q=80&w=1080";
      
      setState(() => _featuredImageUrl = imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection d\'image: $e')),
        );
      }
    }
  }

  Future<void> _addAdditionalImage() async {
    try {
      final imageUrl = await "https://images.unsplash.com/photo-1542435503-956c469947f6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDk3MTE5ODd8&ixlib=rb-4.1.0&q=80&w=1080";
      
      setState(() => _additionalImages.add(imageUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ajout d\'image: $e')),
        );
      }
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() => _additionalImages.removeAt(index));
  }

  Future<void> _selectScheduledDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _previewPost() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final previewPost = _createBlogPostFromForm();
    
    showDialog(
      context: context,
      builder: (context) => BlogPostPreviewDialog(post: previewPost),
    );
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStatus == BlogPostStatus.scheduled && _scheduledDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de publication')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final post = _createBlogPostFromForm();
      
      if (widget.post == null) {
        // Créer un nouvel article
        await BlogFirebaseService.createPost(post);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article créé avec succès')),
          );
        }
      } else {
        // Mettre à jour l'article existant
        await BlogFirebaseService.updatePost(widget.post!.id, post);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article mis à jour avec succès')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  BlogPost _createBlogPostFromForm() {
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final seoData = {
      'metaTitle': _metaTitleController.text.trim(),
      'metaDescription': _metaDescriptionController.text.trim(),
    };

    return BlogPost(
      id: widget.post?.id ?? '',
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      excerpt: _excerptController.text.trim(),
      authorId: widget.post?.authorId ?? '',
      authorName: widget.post?.authorName ?? '',
      authorPhotoUrl: widget.post?.authorPhotoUrl,
      categories: _selectedCategories,
      tags: tags,
      featuredImageUrl: _featuredImageUrl,
      imageUrls: _additionalImages,
      status: _selectedStatus,
      createdAt: widget.post?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      publishedAt: _selectedStatus == BlogPostStatus.published 
          ? DateTime.now() 
          : widget.post?.publishedAt,
      scheduledAt: _scheduledDate,
      views: widget.post?.views ?? 0,
      likes: widget.post?.likes ?? 0,
      commentsCount: widget.post?.commentsCount ?? 0,
      allowComments: _allowComments,
      isFeatured: _isFeatured,
      seoData: seoData,
    );
  }
}