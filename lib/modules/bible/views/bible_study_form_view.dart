import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/bible_study.dart';

class BibleStudyFormView extends StatefulWidget {
  final BibleStudy? study;
  final VoidCallback? onSaved;

  const BibleStudyFormView({
    Key? key,
    this.study,
    this.onSaved,
  }) : super(key: key);

  @override
  State<BibleStudyFormView> createState() => _BibleStudyFormViewState();
}

class _BibleStudyFormViewState extends State<BibleStudyFormView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  
  // Contrôleurs pour les champs de base
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  
  String _selectedCategory = 'Nouveau Testament';
  String _selectedDifficulty = 'beginner';
  bool _isPopular = false;
  bool _isActive = true;
  bool _isSaving = false;
  
  List<String> _tags = [];
  final _tagController = TextEditingController();
  
  // Liste des leçons
  List<BibleStudyLesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    if (widget.study != null) {
      _loadExistingStudy();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _imageUrlController.dispose();
    _estimatedDurationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _loadExistingStudy() {
    final study = widget.study!;
    _titleController.text = study.title;
    _descriptionController.text = study.description;
    _authorController.text = study.author;
    _imageUrlController.text = study.imageUrl;
    _estimatedDurationController.text = study.estimatedDuration.toString();
    _selectedCategory = study.category;
    _selectedDifficulty = study.difficulty;
    _isPopular = study.isPopular;
    _isActive = study.isActive;
    _tags = List.from(study.tags);
    _lessons = List.from(study.lessons);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.study == null ? 'Nouvelle étude' : 'Modifier l\'étude',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveStudy,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    'Sauvegarder',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16)),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary),
              labelColor: Theme.of(context).colorScheme.surfaceColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Informations'),
                Tab(text: 'Leçons'),
                Tab(text: 'Aperçu'),
              ])))),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildLessonsTab(),
            _buildPreviewTab(),
          ])));
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations générales',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Titre
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Titre de l\'étude *',
              hintText: 'Ex: Les Paraboles de Jésus',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              return null;
            }),
          
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description *',
              hintText: 'Décrivez le contenu et l\'objectif de cette étude',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La description est obligatoire';
              }
              return null;
            }),
          
          const SizedBox(height: 16),
          
          // Auteur
          TextFormField(
            controller: _authorController,
            decoration: InputDecoration(
              labelText: 'Auteur *',
              hintText: 'Nom de l\'auteur de l\'étude',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'auteur est obligatoire';
              }
              return null;
            }),
          
          const SizedBox(height: 20),
          
          // Catégorie et difficulté
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  items: [
                    'Nouveau Testament',
                    'Ancien Testament',
                    'Spiritualité',
                    'Théologie',
                    'Paraboles',
                    'Prophétie',
                    'Histoire',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  })),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  decoration: InputDecoration(
                    labelText: 'Difficulté',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Débutant')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'advanced', child: Text('Avancé')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedDifficulty = value!);
                  })),
            ]),
          
          const SizedBox(height: 16),
          
          // Durée estimée
          TextFormField(
            controller: _estimatedDurationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Durée totale estimée (minutes) *',
              hintText: '120',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La durée est obligatoire';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Durée invalide';
              }
              return null;
            }),
          
          const SizedBox(height: 16),
          
          // URL de l'image
          TextFormField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'URL de l\'image',
              hintText: 'https://example.com/image.jpg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)))),
          
          const SizedBox(height: 20),
          
          // Tags
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mots-clés',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'Ajouter un mot-clé',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
                      onSubmitted: _addTag)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addTag(_tagController.text),
                    icon: const Icon(Icons.add)),
                ]),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                    deleteIcon: const Icon(Icons.close, size: 18));
                }).toList()),
            ]),
          
          const SizedBox(height: 20),
          
          // Options
          Text(
            'Options',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          SwitchListTile(
            title: Text(
              'Étude populaire',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            subtitle: Text(
              'Mettre en avant cette étude',
              style: GoogleFonts.inter(fontSize: 12)),
            value: _isPopular,
            onChanged: (value) {
              setState(() => _isPopular = value);
            }),
          
          SwitchListTile(
            title: Text(
              'Étude active',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            subtitle: Text(
              'Rendre cette étude disponible aux utilisateurs',
              style: GoogleFonts.inter(fontSize: 12)),
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
            }),
        ]));
  }

  Widget _buildLessonsTab() {
    return Column(
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${_lessons.length} leçon(s)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addLesson,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter')),
            ])),
        
        // Liste des leçons
        Expanded(
          child: _lessons.isEmpty
              ? _buildEmptyLessonsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lessons.length,
                  itemBuilder: (context, index) {
                    return _buildLessonCard(_lessons[index], index);
                  })),
      ]);
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu de l\'étude',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          _buildPreviewCard(),
          
          const SizedBox(height: 24),
          
          if (_lessons.isNotEmpty) ...[
            Text(
              'Leçons (${_lessons.length})',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ..._lessons.take(3).map((lesson) => _buildPreviewLessonCard(lesson)),
            
            if (_lessons.length > 3)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '... et ${_lessons.length - 3} autres leçons',
                  style: GoogleFonts.inter(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))),
          ],
        ]));
  }

  Widget _buildPreviewCard() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  Icons.school,
                  color: theme.colorScheme.primary,
                  size: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.isEmpty ? 'Titre de l\'étude' : _titleController.text,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                    Text(
                      'Par ${_authorController.text.isEmpty ? 'Auteur' : _authorController.text}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  ])),
              if (_isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.warningColor,
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'POPULAIRE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.surfaceColor))),
            ]),
          
          const SizedBox(height: 16),
          
          Text(
            _descriptionController.text.isEmpty 
                ? 'Description de l\'étude' 
                : _descriptionController.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4)),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildInfoChip('${_lessons.length} leçons'),
              const SizedBox(width: 8),
              _buildInfoChip(_selectedCategory),
              const SizedBox(width: 8),
              _buildInfoChip(_getDifficultyDisplay()),
            ]),
          
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.primary)));
              }).toList()),
          ],
        ]));
  }

  Widget _buildInfoChip(String label) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500)));
  }

  Widget _buildPreviewLessonCard(BibleStudyLesson lesson) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leçon ${lesson.order}: ${lesson.title}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          if (lesson.references.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Lectures: ${lesson.references.map((r) => r.displayText).join(', ')}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ]));
  }

  Widget _buildEmptyLessonsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aucune leçon',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des leçons pour construire votre étude',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addLesson,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une leçon')),
        ]));
  }

  Widget _buildLessonCard(BibleStudyLesson lesson, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          'Leçon ${lesson.order}: ${lesson.title}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${lesson.estimatedDuration}min • ${lesson.references.length} passage(s)',
          style: GoogleFonts.inter(fontSize: 12)),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleLessonAction(action, index),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'duplicate', child: Text('Dupliquer')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ]),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lesson.content.isNotEmpty) ...[
                  Text(
                    'Contenu:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Text(lesson.content),
                  const SizedBox(height: 8),
                ],
                if (lesson.references.isNotEmpty) ...[
                  Text(
                    'Passages bibliques:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ...lesson.references.map((ref) => Text('• ${ref.displayText}')),
                  const SizedBox(height: 8),
                ],
                if (lesson.questions.isNotEmpty) ...[
                  Text(
                    'Questions (${lesson.questions.length}):',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ...lesson.questions.take(2).map((q) => Text('• ${q.question}')),
                  if (lesson.questions.length > 2)
                    Text('• ... et ${lesson.questions.length - 2} autres questions'),
                ],
              ])),
        ]));
  }

  String _getDifficultyDisplay() {
    switch (_selectedDifficulty) {
      case 'beginner':
        return 'Débutant';
      case 'intermediate':
        return 'Intermédiaire';
      case 'advanced':
        return 'Avancé';
      default:
        return 'Débutant';
    }
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addLesson() {
    // Pour la démonstration, créons une leçon simple
    final newLesson = BibleStudyLesson(
      id: _uuid.v4(),
      title: 'Nouvelle leçon',
      content: 'Contenu de la leçon...',
      references: [],
      questions: [],
      order: _lessons.length + 1,
      estimatedDuration: 30);
    
    setState(() {
      _lessons.add(newLesson);
    });
    
    // TODO: Ouvrir un dialogue d'édition de leçon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leçon ajoutée ! (Édition complète à implémenter)')));
  }

  void _handleLessonAction(String action, int index) {
    switch (action) {
      case 'edit':
        // TODO: Éditer la leçon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Édition de leçon à implémenter')));
        break;
      case 'duplicate':
        final original = _lessons[index];
        final duplicate = BibleStudyLesson(
          id: _uuid.v4(),
          title: '${original.title} (copie)',
          content: original.content,
          references: List.from(original.references),
          questions: List.from(original.questions),
          order: _lessons.length + 1,
          estimatedDuration: original.estimatedDuration,
          reflection: original.reflection,
          prayer: original.prayer);
        setState(() {
          _lessons.add(duplicate);
        });
        break;
      case 'delete':
        setState(() {
          _lessons.removeAt(index);
          // Réorganiser les numéros d'ordre
          for (int i = 0; i < _lessons.length; i++) {
            _lessons[i] = _lessons[i].copyWith(order: i + 1);
          }
        });
        break;
    }
  }

  Future<void> _saveStudy() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }
    
    if (_lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une leçon à l\'étude')));
      _tabController.animateTo(1);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final study = BibleStudy(
        id: widget.study?.id ?? _uuid.v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        estimatedDuration: int.parse(_estimatedDurationController.text),
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? 'assets/illustrations/default_study.png' 
            : _imageUrlController.text.trim(),
        lessons: _lessons,
        createdAt: widget.study?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isPopular: _isPopular,
        isActive: _isActive,
        author: _authorController.text.trim(),
        tags: _tags);
      
      // TODO: Sauvegarder l'étude via le service
      await _saveStudyToStorage(study);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.study == null 
                  ? 'Étude créée avec succès' 
                  : 'Étude mise à jour avec succès'
            ),
            backgroundColor: Theme.of(context).colorScheme.successColor));
        
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveStudyToStorage(BibleStudy study) async {
    // TODO: Implémenter la sauvegarde réelle
    await Future.delayed(const Duration(seconds: 1));
  }
}
