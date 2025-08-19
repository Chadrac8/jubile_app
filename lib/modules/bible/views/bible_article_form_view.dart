import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bible_article.dart';
import '../services/bible_article_service.dart';

class BibleArticleFormView extends StatefulWidget {
  final BibleArticle? article;

  const BibleArticleFormView({
    super.key,
    this.article,
  });

  @override
  State<BibleArticleFormView> createState() => _BibleArticleFormViewState();
}

class _BibleArticleFormViewState extends State<BibleArticleFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final BibleArticleService _articleService = BibleArticleService.instance;
  
  // Contrôleurs de texte
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _readingTimeController = TextEditingController();
  
  // Références bibliques
  List<BibleReference> _bibleReferences = [];
  final TextEditingController _refBookController = TextEditingController();
  final TextEditingController _refChapterController = TextEditingController();
  final TextEditingController _refStartVerseController = TextEditingController();
  final TextEditingController _refEndVerseController = TextEditingController();
  
  String _selectedCategory = BibleArticleCategory.theology.displayName;
  bool _isPublished = true;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.article != null;
    
    if (_isEditing) {
      _populateFields();
    } else {
      _readingTimeController.text = '5';
    }
  }

  void _populateFields() {
    final article = widget.article!;
    _titleController.text = article.title;
    _summaryController.text = article.summary;
    _contentController.text = article.content;
    _authorController.text = article.author;
    _imageUrlController.text = article.imageUrl ?? '';
    _readingTimeController.text = article.readingTimeMinutes.toString();
    _tagsController.text = article.tags.join(', ');
    _selectedCategory = article.category;
    _isPublished = article.isPublished;
    _bibleReferences = List.from(article.bibleReferences);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose();
    _readingTimeController.dispose();
    _refBookController.dispose();
    _refChapterController.dispose();
    _refStartVerseController.dispose();
    _refEndVerseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier l\'article' : 'Nouvel article',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveArticle,
            child: Text(
              _isEditing ? 'Mettre à jour' : 'Publier',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _isLoading ? theme.hintColor : theme.primaryColor))),
        ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(theme),
                    const SizedBox(height: 24),
                    _buildContentSection(theme),
                    const SizedBox(height: 24),
                    _buildBibleReferencesSection(theme),
                    const SizedBox(height: 24),
                    _buildMetadataSection(theme),
                    const SizedBox(height: 32),
                    _buildPublishSection(theme),
                  ]))));
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de base',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 16),
            
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titre de l\'article *',
                hintText: 'Entrez un titre accrocheur',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12))),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
              maxLines: 2),
            const SizedBox(height: 16),
            
            // Résumé
            TextFormField(
              controller: _summaryController,
              decoration: InputDecoration(
                labelText: 'Résumé *',
                hintText: 'Décrivez brièvement le contenu de l\'article',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12))),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le résumé est requis';
                }
                return null;
              },
              maxLines: 3),
            const SizedBox(height: 16),
            
            // Catégorie et Auteur
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                    decoration: InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                    items: _articleService.getAvailableCategories()
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category)))
                        .toList())),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _authorController,
                    decoration: InputDecoration(
                      labelText: 'Auteur *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'auteur est requis';
                      }
                      return null;
                    })),
              ]),
          ])));
  }

  Widget _buildContentSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contenu de l\'article',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Contenu de l\'article *',
                hintText: 'Rédigez le contenu complet de votre article...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le contenu est requis';
                }
                return null;
              },
              maxLines: 15,
              minLines: 10),
          ])));
  }

  Widget _buildBibleReferencesSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Références bibliques',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color))),
                IconButton(
                  onPressed: _showAddReferenceDialog,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter une référence'),
              ]),
            const SizedBox(height: 16),
            
            if (_bibleReferences.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.hintColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.hintColor),
                    const SizedBox(width: 8),
                    Text(
                      'Aucune référence biblique ajoutée',
                      style: GoogleFonts.inter(color: theme.hintColor)),
                  ]))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bibleReferences.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final ref = _bibleReferences[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2))),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          color: theme.primaryColor,
                          size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ref.displayText,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: theme.primaryColor))),
                        IconButton(
                          onPressed: () => _removeReference(index),
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Supprimer'),
                      ]));
                }),
          ])));
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métadonnées',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 16),
            
            // Mots-clés
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Mots-clés',
                hintText: 'Séparez les mots-clés par des virgules',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            
            // Temps de lecture et URL image
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _readingTimeController,
                    decoration: InputDecoration(
                      labelText: 'Temps de lecture (min)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final time = int.tryParse(value);
                        if (time == null || time <= 0) {
                          return 'Temps invalide';
                        }
                      }
                      return null;
                    })),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL de l\'image (optionnel)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))))),
              ]),
          ])));
  }

  Widget _buildPublishSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publication',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color)),
            const SizedBox(height: 16),
            
            SwitchListTile(
              value: _isPublished,
              onChanged: (value) => setState(() => _isPublished = value),
              title: Text(
                'Publier l\'article',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              subtitle: Text(
                _isPublished 
                    ? 'L\'article sera visible par tous les utilisateurs'
                    : 'L\'article restera en brouillon',
                style: GoogleFonts.inter(fontSize: 13))),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveArticle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: AppTheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
                child: Text(
                  _isEditing ? 'Mettre à jour l\'article' : 'Créer l\'article',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600)))),
          ])));
  }

  void _showAddReferenceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une référence biblique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _refBookController,
              decoration: const InputDecoration(
                labelText: 'Livre',
                hintText: 'Ex: Matthieu, Genèse...')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _refChapterController,
                    decoration: const InputDecoration(
                      labelText: 'Chapitre'),
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _refStartVerseController,
                    decoration: const InputDecoration(
                      labelText: 'Verset début'),
                    keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _refEndVerseController,
                    decoration: const InputDecoration(
                      labelText: 'Verset fin'),
                    keyboardType: TextInputType.number)),
              ]),
          ]),
        actions: [
          TextButton(
            onPressed: () {
              _refBookController.clear();
              _refChapterController.clear();
              _refStartVerseController.clear();
              _refEndVerseController.clear();
              Navigator.pop(context);
            },
            child: const Text('Annuler')),
          TextButton(
            onPressed: _addReference,
            child: const Text('Ajouter')),
        ]));
  }

  void _addReference() {
    if (_refBookController.text.isNotEmpty && _refChapterController.text.isNotEmpty) {
      final chapter = int.tryParse(_refChapterController.text);
      final startVerse = _refStartVerseController.text.isNotEmpty 
          ? int.tryParse(_refStartVerseController.text) 
          : null;
      final endVerse = _refEndVerseController.text.isNotEmpty 
          ? int.tryParse(_refEndVerseController.text) 
          : null;

      if (chapter != null) {
        final reference = BibleReference(
          book: _refBookController.text.trim(),
          chapter: chapter,
          startVerse: startVerse,
          endVerse: endVerse);

        setState(() {
          _bibleReferences.add(reference);
        });

        _refBookController.clear();
        _refChapterController.clear();
        _refStartVerseController.clear();
        _refEndVerseController.clear();
        
        Navigator.pop(context);
      }
    }
  }

  void _removeReference(int index) {
    setState(() {
      _bibleReferences.removeAt(index);
    });
  }

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final readingTime = int.tryParse(_readingTimeController.text) ?? 5;

      if (_isEditing) {
        final updatedArticle = widget.article!.copyWith(
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          author: _authorController.text.trim(),
          tags: tags,
          bibleReferences: _bibleReferences,
          imageUrl: _imageUrlController.text.trim().isEmpty 
              ? null 
              : _imageUrlController.text.trim(),
          readingTimeMinutes: readingTime,
          isPublished: _isPublished,
          updatedAt: DateTime.now());

        await _articleService.updateArticle(updatedArticle);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article mis à jour avec succès')));
        
        Navigator.pop(context, updatedArticle);
      } else {
        final newArticle = BibleArticle(
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          author: _authorController.text.trim(),
          tags: tags,
          bibleReferences: _bibleReferences,
          imageUrl: _imageUrlController.text.trim().isEmpty 
              ? null 
              : _imageUrlController.text.trim(),
          readingTimeMinutes: readingTime,
          isPublished: _isPublished);

        await _articleService.addArticle(newArticle);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article créé avec succès')));
        
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
