import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../widgets/form_responses_list.dart';
import '../widgets/form_statistics_view.dart';
import 'form_builder_page.dart';
import '../theme.dart';

class FormDetailPage extends StatefulWidget {
  final FormModel form;

  const FormDetailPage({
    super.key,
    required this.form,
  });

  @override
  State<FormDetailPage> createState() => _FormDetailPageState();
}

class _FormDetailPageState extends State<FormDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  FormModel? _currentForm;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentForm = widget.form;
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
    super.dispose();
  }

  Future<void> _refreshFormData() async {
    setState(() => _isLoading = true);
    try {
      final updatedForm = await FormsFirebaseService.getForm(widget.form.id);
      if (updatedForm != null) {
        setState(() => _currentForm = updatedForm);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du rechargement: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormBuilderPage(form: _currentForm),
      ),
    );
    
    if (result == true) {
      await _refreshFormData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire mis à jour avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _publishForm() async {
    if (_currentForm?.status == 'publie') return;
    
    setState(() => _isLoading = true);
    try {
      final updatedForm = _currentForm!.copyWith(
        status: 'publie',
        publishDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await FormsFirebaseService.updateForm(updatedForm);
      setState(() => _currentForm = updatedForm);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire publié avec succès'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _duplicateForm() async {
    setState(() => _isLoading = true);
    try {
      await FormsFirebaseService.duplicateForm(
        _currentForm!.id,
        '${_currentForm!.title} (Copie)',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formulaire dupliqué avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la duplication: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _copyFormUrl() {
    final url = FormsFirebaseService.generatePublicFormUrl(_currentForm!.id);
    Clipboard.setData(ClipboardData(text: url));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié dans le presse-papiers'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Color get _statusColor {
    switch (_currentForm?.status) {
      case 'brouillon': return AppTheme.warningColor;
      case 'publie': return AppTheme.successColor;
      case 'archive': return AppTheme.textTertiaryColor;
      default: return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentForm == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Formulaire'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Formulaire introuvable'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshFormData,
                ),
                PopupMenuButton<String>(
                  onSelected: _handleAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_currentForm!.status != 'publie')
                      const PopupMenuItem(
                        value: 'publish',
                        child: ListTile(
                          leading: Icon(Icons.publish),
                          title: Text('Publier'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (_currentForm!.isPublished)
                      const PopupMenuItem(
                        value: 'copy_url',
                        child: ListTile(
                          leading: Icon(Icons.link),
                          title: Text('Copier le lien'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.content_copy),
                        title: Text('Dupliquer'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'archive',
                      child: ListTile(
                        leading: Icon(Icons.archive),
                        title: Text('Archiver'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _currentForm!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 80), // Space for app bar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _currentForm!.statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _currentForm!.accessibilityLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentForm!.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryColor,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  tabs: const [
                    Tab(text: 'Aperçu'),
                    Tab(text: 'Réponses'),
                    Tab(text: 'Statistiques'),
                    Tab(text: 'Paramètres'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildResponsesTab(),
            _buildStatisticsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _currentForm!.isPublished ? _copyFormUrl : _publishForm,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: Icon(_currentForm!.isPublished ? Icons.link : Icons.publish),
          label: Text(_currentForm!.isPublished ? 'Copier le lien' : 'Publier'),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Informations générales',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow(
                icon: Icons.title,
                label: 'Titre',
                value: _currentForm!.title,
              ),
              if (_currentForm!.description.isNotEmpty)
                _buildInfoRow(
                  icon: Icons.description,
                  label: 'Description',
                  value: _currentForm!.description,
                ),
              _buildInfoRow(
                icon: Icons.visibility,
                label: 'Accessibilité',
                value: _currentForm!.accessibilityLabel,
              ),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Créé le',
                value: _formatDateTime(_currentForm!.createdAt),
              ),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Modifié le',
                value: _formatDateTime(_currentForm!.updatedAt),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'Champs du formulaire',
            icon: Icons.quiz,
            children: [
              Text(
                '${_currentForm!.fields.where((f) => f.isInputField).length} champs de saisie',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_currentForm!.fields.length, (index) {
                final field = _currentForm!.fields[index];
                return _buildFieldPreview(field);
              }),
            ],
          ),
          
          if (_currentForm!.publishDate != null || _currentForm!.closeDate != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Dates de publication',
              icon: Icons.schedule,
              children: [
                if (_currentForm!.publishDate != null)
                  _buildInfoRow(
                    icon: Icons.publish,
                    label: 'Date de publication',
                    value: _formatDateTime(_currentForm!.publishDate!),
                  ),
                if (_currentForm!.closeDate != null)
                  _buildInfoRow(
                    icon: Icons.event_busy,
                    label: 'Date de fermeture',
                    value: _formatDateTime(_currentForm!.closeDate!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsesTab() {
    return FormResponsesList(form: _currentForm!);
  }

  Widget _buildStatisticsTab() {
    return FormStatisticsView(form: _currentForm!);
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Paramètres de soumission',
            icon: Icons.settings,
            children: [
              if (_currentForm!.hasSubmissionLimit)
                _buildInfoRow(
                  icon: Icons.people,
                  label: 'Limite de soumissions',
                  value: _currentForm!.submissionLimit.toString(),
                ),
              _buildInfoRow(
                icon: Icons.repeat,
                label: 'Soumissions multiples',
                value: _currentForm!.settings.allowMultipleSubmissions ? 'Autorisées' : 'Interdites',
              ),
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email de confirmation',
                value: _currentForm!.settings.sendConfirmationEmail ? 'Activé' : 'Désactivé',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'Actions post-soumission',
            icon: Icons.auto_fix_high,
            children: [
              _buildInfoRow(
                icon: Icons.message,
                label: 'Message de confirmation',
                value: _currentForm!.settings.confirmationMessage,
              ),
              if (_currentForm!.settings.autoAddToGroup)
                _buildInfoRow(
                  icon: Icons.group_add,
                  label: 'Ajout automatique au groupe',
                  value: 'Activé',
                ),
              if (_currentForm!.settings.autoAddToWorkflow)
                _buildInfoRow(
                  icon: Icons.timeline,
                  label: 'Ajout automatique au workflow',
                  value: 'Activé',
                ),
            ],
          ),
          
          if (_currentForm!.settings.notificationEmails.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                Text(
                  'Emails de notification:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_currentForm!.settings.notificationEmails.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${_currentForm!.settings.notificationEmails[index]}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldPreview(CustomFormField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textTertiaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFieldIcon(field.type),
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label.isNotEmpty ? field.label : field.typeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (field.helpText != null)
                  Text(
                    field.helpText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
          if (field.isRequired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Obligatoire',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'text': return Icons.text_fields;
      case 'textarea': return Icons.subject;
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'checkbox': return Icons.check_box;
      case 'radio': return Icons.radio_button_checked;
      case 'select': return Icons.arrow_drop_down;
      case 'date': return Icons.calendar_today;
      case 'time': return Icons.access_time;
      case 'file': return Icons.attach_file;
      case 'signature': return Icons.edit;
      case 'section': return Icons.view_headline;
      case 'title': return Icons.title;
      case 'instructions': return Icons.info;
      case 'person_field': return Icons.person;
      default: return Icons.help_outline;
    }
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'edit':
        await _editForm();
        break;
      case 'publish':
        await _publishForm();
        break;
      case 'copy_url':
        _copyFormUrl();
        break;
      case 'duplicate':
        await _duplicateForm();
        break;
      case 'archive':
        // TODO: Implement archive action
        break;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}