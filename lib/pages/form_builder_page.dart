import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../widgets/form_field_editor.dart';
import '../theme.dart';

class FormBuilderPage extends StatefulWidget {
  final FormModel? form;
  final FormTemplate? template;

  const FormBuilderPage({
    super.key,
    this.form,
    this.template,
  });

  @override
  State<FormBuilderPage> createState() => _FormBuilderPageState();
}

class _FormBuilderPageState extends State<FormBuilderPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _confirmationMessageController = TextEditingController();
  
  // Form values
  String? _headerImageUrl;
  String _status = 'brouillon';
  DateTime? _publishDate;
  DateTime? _closeDate;
  int? _submissionLimit;
  String _accessibility = 'public';
  List<String> _accessibilityTargets = [];
  String _displayMode = 'single_page';
  List<CustomFormField> _fields = [];
  FormSettings _settings = FormSettings();
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  final List<Map<String, dynamic>> _fieldTypes = [
    {'type': 'text', 'label': 'Texte court', 'icon': Icons.text_fields, 'category': 'Texte'},
    {'type': 'textarea', 'label': 'Texte long', 'icon': Icons.subject, 'category': 'Texte'},
    {'type': 'email', 'label': 'Email', 'icon': Icons.email, 'category': 'Contact'},
    {'type': 'phone', 'label': 'Téléphone', 'icon': Icons.phone, 'category': 'Contact'},
    {'type': 'checkbox', 'label': 'Cases à cocher', 'icon': Icons.check_box, 'category': 'Choix'},
    {'type': 'radio', 'label': 'Boutons radio', 'icon': Icons.radio_button_checked, 'category': 'Choix'},
    {'type': 'select', 'label': 'Liste déroulante', 'icon': Icons.arrow_drop_down, 'category': 'Choix'},
    {'type': 'date', 'label': 'Date', 'icon': Icons.calendar_today, 'category': 'Date/Heure'},
    {'type': 'time', 'label': 'Heure', 'icon': Icons.access_time, 'category': 'Date/Heure'},
    {'type': 'file', 'label': 'Fichier', 'icon': Icons.attach_file, 'category': 'Média'},
    {'type': 'signature', 'label': 'Signature', 'icon': Icons.edit, 'category': 'Média'},
    {'type': 'section', 'label': 'Section', 'icon': Icons.view_headline, 'category': 'Mise en forme'},
    {'type': 'title', 'label': 'Titre', 'icon': Icons.title, 'category': 'Mise en forme'},
    {'type': 'instructions', 'label': 'Instructions', 'icon': Icons.info, 'category': 'Mise en forme'},
    {'type': 'person_field', 'label': 'Champ personne', 'icon': Icons.person, 'category': 'Données'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _initializeForm();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _confirmationMessageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.form != null) {
      // Editing existing form
      final form = widget.form!;
      _titleController.text = form.title;
      _descriptionController.text = form.description;
      _headerImageUrl = form.headerImageUrl;
      _status = form.status;
      _publishDate = form.publishDate;
      _closeDate = form.closeDate;
      _submissionLimit = form.submissionLimit;
      _accessibility = form.accessibility;
      _accessibilityTargets = List.from(form.accessibilityTargets);
      _displayMode = form.displayMode;
      _fields = List.from(form.fields);
      _settings = form.settings;
      _confirmationMessageController.text = _settings.confirmationMessage;
    } else if (widget.template != null) {
      // Creating from template
      final template = widget.template!;
      _titleController.text = template.name;
      _descriptionController.text = template.description;
      _fields = List.from(template.fields);
      _settings = template.defaultSettings;
      _confirmationMessageController.text = _settings.confirmationMessage;
    } else {
      // New form with default values
      _confirmationMessageController.text = _settings.confirmationMessage;
    }
  }

  void _markAsChanged() {
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settings = FormSettings(
        confirmationMessage: _confirmationMessageController.text,
        redirectUrl: _settings.redirectUrl,
        sendConfirmationEmail: _settings.sendConfirmationEmail,
        confirmationEmailTemplate: _settings.confirmationEmailTemplate,
        notificationEmails: _settings.notificationEmails,
        autoAddToGroup: _settings.autoAddToGroup,
        targetGroupId: _settings.targetGroupId,
        autoAddToWorkflow: _settings.autoAddToWorkflow,
        targetWorkflowId: _settings.targetWorkflowId,
        allowMultipleSubmissions: _settings.allowMultipleSubmissions,
        showProgressBar: _settings.showProgressBar,
        enableTestMode: _settings.enableTestMode,
        postSubmissionActions: _settings.postSubmissionActions,
      );

      if (widget.form != null) {
        // Update existing form
        final updatedForm = widget.form!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          headerImageUrl: _headerImageUrl,
          status: _status,
          publishDate: _publishDate,
          closeDate: _closeDate,
          submissionLimit: _submissionLimit,
          accessibility: _accessibility,
          accessibilityTargets: _accessibilityTargets,
          displayMode: _displayMode,
          fields: _fields,
          settings: settings,
          updatedAt: DateTime.now(),
        );
        
        await FormsFirebaseService.updateForm(updatedForm);
      } else {
        // Create new form
        final newForm = FormModel(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          headerImageUrl: _headerImageUrl,
          status: _status,
          publishDate: _publishDate,
          closeDate: _closeDate,
          submissionLimit: _submissionLimit,
          accessibility: _accessibility,
          accessibilityTargets: _accessibilityTargets,
          displayMode: _displayMode,
          fields: _fields,
          settings: settings,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await FormsFirebaseService.createForm(newForm);
      }

      setState(() => _hasUnsavedChanges = false);
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addField(Map<String, dynamic> fieldData) {
    final newField = CustomFormField(
      id: _uuid.v4(),
      type: fieldData['type'],
      label: fieldData['label'],
      order: _fields.length,
    );
    
    setState(() {
      _fields.add(newField);
      _markAsChanged();
    });
  }

  void _editField(CustomFormField field) {
    showDialog(
      context: context,
      builder: (context) => FormFieldEditor(
        field: field,
        onSave: (updatedField) {
          setState(() {
            final index = _fields.indexWhere((f) => f.id == field.id);
            if (index != -1) {
              _fields[index] = updatedField;
              _markAsChanged();
            }
          });
        },
      ),
    );
  }

  void _deleteField(CustomFormField field) {
    setState(() {
      _fields.removeWhere((f) => f.id == field.id);
      // Reorder remaining fields
      for (int i = 0; i < _fields.length; i++) {
        _fields[i] = _fields[i].copyWith(order: i);
      }
      _markAsChanged();
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final field = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, field);
      
      // Update order for all fields
      for (int i = 0; i < _fields.length; i++) {
        _fields[i] = _fields[i].copyWith(order: i);
      }
      _markAsChanged();
    });
  }

  void _previewForm() {
    // TODO: Implement form preview
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aperçu'),
        content: const Text('Fonction d\'aperçu en cours de développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showUnsavedChangesDialog();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(widget.form != null ? 'Modifier le formulaire' : 'Nouveau formulaire'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _previewForm,
            ),
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: const Icon(
                  Icons.circle,
                  color: AppTheme.warningColor,
                  size: 8,
                ),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: _buildBody(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _saveForm,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'Sauvegarde...' : 'Sauvegarder'),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Row(
      children: [
        // Form builder
        Expanded(
          flex: 2,
          child: _buildFormBuilder(),
        ),
        
        // Field types panel
        Container(
          width: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey, width: 0.5)),
          ),
          child: _buildFieldTypesPanel(),
        ),
      ],
    );
  }

  Widget _buildFormBuilder() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormSettings(),
            const SizedBox(height: 32),
            _buildFieldsList(),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildFormSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres du formulaire',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title and description
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du formulaire *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
              onChanged: (_) => _markAsChanged(),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (_) => _markAsChanged(),
            ),
            const SizedBox(height: 24),
            
            // Status and accessibility
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'brouillon', child: Text('Brouillon')),
                      DropdownMenuItem(value: 'publie', child: Text('Publié')),
                      DropdownMenuItem(value: 'archive', child: Text('Archivé')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                        _markAsChanged();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _accessibility,
                    decoration: const InputDecoration(
                      labelText: 'Accessibilité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                      DropdownMenuItem(value: 'membres', child: Text('Membres connectés')),
                      DropdownMenuItem(value: 'groupe', child: Text('Groupes spécifiques')),
                      DropdownMenuItem(value: 'role', child: Text('Rôles spécifiques')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _accessibility = value!;
                        _markAsChanged();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Advanced settings
            ExpansionTile(
              title: const Text('Paramètres avancés'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _confirmationMessageController,
                        decoration: const InputDecoration(
                          labelText: 'Message de confirmation',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _markAsChanged(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _submissionLimit?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Limite de soumissions',
                          border: OutlineInputBorder(),
                          hintText: 'Laisser vide pour aucune limite',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _submissionLimit = int.tryParse(value);
                          _markAsChanged();
                        },
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

  Widget _buildFieldsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Champs du formulaire',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_fields.length} champ${_fields.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_fields.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textTertiaryColor.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: AppTheme.textTertiaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun champ ajouté',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Glissez-déposez des champs depuis le panneau de droite',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: _reorderFields,
                itemCount: _fields.length,
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  return _buildFieldCard(field, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldCard(CustomFormField field, int index) {
    return Card(
      key: ValueKey(field.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getFieldIcon(field.type),
          color: AppTheme.primaryColor,
        ),
        title: Text(field.label.isNotEmpty ? field.label : field.typeLabel),
        subtitle: Text('${field.typeLabel}${field.isRequired ? ' • Obligatoire' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editField(field),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _deleteField(field),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
        onTap: () => _editField(field),
      ),
    );
  }

  Widget _buildFieldTypesPanel() {
    final groupedFields = <String, List<Map<String, dynamic>>>{};
    for (final fieldType in _fieldTypes) {
      final category = fieldType['category'] as String;
      if (!groupedFields.containsKey(category)) {
        groupedFields[category] = [];
      }
      groupedFields[category]!.add(fieldType);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
          ),
          child: Row(
            children: [
              const Icon(Icons.widgets, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Types de champs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: groupedFields.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  ...entry.value.map((fieldType) => _buildFieldTypeCard(fieldType)),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTypeCard(Map<String, dynamic> fieldType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _addField(fieldType),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  fieldType['icon'] as IconData,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fieldType['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    final fieldType = _fieldTypes.firstWhere(
      (ft) => ft['type'] == type,
      orElse: () => {'icon': Icons.help_outline},
    );
    return fieldType['icon'] as IconData;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
          'Vous avez des modifications non sauvegardées. '
          'Voulez-vous quitter sans sauvegarder ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitter'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              _saveForm();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    ) ?? false;
  }
}