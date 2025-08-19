import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../widgets/form_card.dart';
import 'form_builder_page.dart';
import 'form_detail_page.dart';
import '../theme.dart';

class FormsHomePage extends StatefulWidget {
  const FormsHomePage({super.key});

  @override
  State<FormsHomePage> createState() => _FormsHomePageState();
}

class _FormsHomePageState extends State<FormsHomePage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  String _statusFilter = '';
  String _accessibilityFilter = '';
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late TabController _tabController;
  
  List<FormModel> _selectedForms = [];
  bool _isSelectionMode = false;

  final List<Map<String, String>> _statusFilters = [
    {'value': '', 'label': 'Tous les statuts'},
    {'value': 'brouillon', 'label': 'Brouillons'},
    {'value': 'publie', 'label': 'Publiés'},
    {'value': 'archive', 'label': 'Archivés'},
  ];

  final List<Map<String, String>> _accessibilityFilters = [
    {'value': '', 'label': 'Toutes les visibilités'},
    {'value': 'public', 'label': 'Public'},
    {'value': 'membres', 'label': 'Membres connectés'},
    {'value': 'groupe', 'label': 'Groupes spécifiques'},
    {'value': 'role', 'label': 'Rôles spécifiques'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() => _statusFilter = status ?? '');
  }

  void _onAccessibilityFilterChanged(String? accessibility) {
    setState(() => _accessibilityFilter = accessibility ?? '');
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedForms.clear();
      }
    });
  }

  void _onFormSelected(FormModel form, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedForms.add(form);
      } else {
        _selectedForms.removeWhere((f) => f.id == form.id);
      }
    });
  }

  Future<void> _createNewForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormBuilderPage(),
      ),
    );
    
    if (result == true) {
      // Form created successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire créé avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _createFromTemplate() async {
    try {
      final templates = await FormsFirebaseService.getFormTemplates();
      
      if (!mounted) return;
      
      final selectedTemplate = await showDialog<FormTemplate>(
        context: context,
        builder: (context) => _TemplateSelectionDialog(templates: templates),
      );
      
      if (selectedTemplate != null) {
        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FormBuilderPage(template: selectedTemplate),
          ),
        );
        
        if (result == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formulaire créé à partir du modèle'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des modèles: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _performBulkAction(String action) async {
    switch (action) {
      case 'publish':
        await _publishSelectedForms();
        break;
      case 'archive':
        await _archiveSelectedForms();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _publishSelectedForms() async {
    try {
      for (final form in _selectedForms) {
        if (form.status != 'publie') {
          final updatedForm = form.copyWith(
            status: 'publie',
            publishDate: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await FormsFirebaseService.updateForm(updatedForm);
        }
      }
      
      setState(() {
        _selectedForms.clear();
        _isSelectionMode = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedForms.length} formulaire(s) publié(s)'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la publication: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _archiveSelectedForms() async {
    try {
      for (final form in _selectedForms) {
        await FormsFirebaseService.archiveForm(form.id);
      }
      
      setState(() {
        _selectedForms.clear();
        _isSelectionMode = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedForms.length} formulaire(s) archivé(s)'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'archivage: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_selectedForms.length} formulaire(s) ?\n\n'
          'Cette action supprimera également toutes les soumissions associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final form in _selectedForms) {
          await FormsFirebaseService.deleteForm(form.id);
        }
        
        setState(() {
          _selectedForms.clear();
          _isSelectionMode = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedForms.length} formulaire(s) supprimé(s)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _copyFormUrl(FormModel form) {
    final url = FormsFirebaseService.generatePublicFormUrl(form.id);
    Clipboard.setData(ClipboardData(text: url));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié dans le presse-papiers'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Formulaires'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showBulkActionsMenu,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Brouillons'),
            Tab(text: 'Publiés'),
            Tab(text: 'Archivés'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFormsList(''),
                _buildFormsList('brouillon'),
                _buildFormsList('publie'),
                _buildFormsList('archive'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showCreateOptions,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nouveau'),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher des formulaires...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter.isEmpty ? null : _statusFilter,
                  onChanged: _onStatusFilterChanged,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusFilters.map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter['value']!.isEmpty ? null : filter['value'],
                      child: Text(filter['label']!),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _accessibilityFilter.isEmpty ? null : _accessibilityFilter,
                  onChanged: _onAccessibilityFilterChanged,
                  decoration: InputDecoration(
                    labelText: 'Visibilité',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _accessibilityFilters.map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter['value']!.isEmpty ? null : filter['value'],
                      child: Text(filter['label']!),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList(String statusFilter) {
    return StreamBuilder<List<FormModel>>(
      stream: FormsFirebaseService.getFormsStream(
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        statusFilter: statusFilter.isNotEmpty ? statusFilter : _statusFilter.isNotEmpty ? _statusFilter : null,
        accessibilityFilter: _accessibilityFilter.isNotEmpty ? _accessibilityFilter : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des formulaires',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        final forms = snapshot.data ?? [];

        if (forms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: AppTheme.textTertiaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun formulaire trouvé',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre premier formulaire',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createNewForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un formulaire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: forms.length,
          itemBuilder: (context, index) {
            final form = forms[index];
            return FormCard(
              form: form,
              onTap: () => _onFormTap(form),
              onLongPress: () => _onFormLongPress(form),
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedForms.any((f) => f.id == form.id),
              onSelectionChanged: (isSelected) => _onFormSelected(form, isSelected),
              onCopyUrl: () => _copyFormUrl(form),
            );
          },
        );
      },
    );
  }

  void _onFormTap(FormModel form) {
    if (_isSelectionMode) {
      final isSelected = _selectedForms.any((f) => f.id == form.id);
      _onFormSelected(form, !isSelected);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormDetailPage(form: form),
        ),
      );
    }
  }

  void _onFormLongPress(FormModel form) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _onFormSelected(form, true);
    }
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Créer un formulaire',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
              title: const Text('Formulaire vierge'),
              subtitle: const Text('Commencer avec un formulaire vide'),
              onTap: () {
                Navigator.pop(context);
                _createNewForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, color: AppTheme.secondaryColor),
              title: const Text('À partir d\'un modèle'),
              subtitle: const Text('Utiliser un modèle prédéfini'),
              onTap: () {
                Navigator.pop(context);
                _createFromTemplate();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_selectedForms.length} formulaire(s) sélectionné(s)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.publish, color: AppTheme.successColor),
              title: const Text('Publier'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('publish');
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: AppTheme.warningColor),
              title: const Text('Archiver'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('archive');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                _performBulkAction('delete');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSelectionDialog extends StatelessWidget {
  final List<FormTemplate> templates;

  const _TemplateSelectionDialog({required this.templates});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un modèle'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(template.name),
                subtitle: Text(template.description),
                trailing: Chip(
                  label: Text(template.category),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
                onTap: () => Navigator.of(context).pop(template),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}