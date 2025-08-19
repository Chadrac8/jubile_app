import 'package:flutter/material.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import 'form_public_page.dart';

class MemberFormsPage extends StatefulWidget {
  const MemberFormsPage({super.key});

  @override
  State<MemberFormsPage> createState() => _MemberFormsPageState();
}

class _MemberFormsPageState extends State<MemberFormsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<FormModel> _availableForms = [];
  List<FormSubmissionModel> _mySubmissions = [];
  bool _isLoading = true;
  String _selectedTab = 'available';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFormsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadFormsData() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      // Charger les formulaires disponibles
      final formsStream = FormsFirebaseService.getFormsStream(
        statusFilter: 'publie',
        limit: 100,
      );

      await for (final forms in formsStream.take(1)) {
        if (mounted) {
          setState(() {
            _availableForms = forms ?? [];
          });
        }
        break;
      }

      // Charger mes soumissions
      final submissions = await FormsFirebaseService.getUserSubmissions(user.uid);
      if (mounted) {
        setState(() {
          _mySubmissions = submissions ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _fillForm(FormModel form) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FormPublicPage(formId: form.id),
      ),
    );

    if (result == true) {
      // Recharger les données après soumission
      _loadFormsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Formulaires'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTabSelector(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadFormsData,
                      child: _selectedTab == 'available'
                          ? _buildAvailableFormsList()
                          : _buildMySubmissionsList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'available',
              'Disponibles',
              Icons.assignment,
              _availableForms.length,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'submitted',
              'Mes Réponses',
              Icons.assignment_turned_in,
              _mySubmissions.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon, int count) {
    final isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableFormsList() {
    if (_availableForms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun formulaire disponible',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Les formulaires à remplir apparaîtront ici',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableForms.length,
      itemBuilder: (context, index) {
        final form = _availableForms[index];
        final hasSubmitted = _mySubmissions.any((s) => s.formId == form.id);
        return _buildAvailableFormCard(form, hasSubmitted);
      },
    );
  }

  Widget _buildMySubmissionsList() {
    if (_mySubmissions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune réponse soumise',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vos réponses aux formulaires apparaîtront ici',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mySubmissions.length,
      itemBuilder: (context, index) {
        final submission = _mySubmissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildAvailableFormCard(FormModel form, bool hasSubmitted) {
    final isOpen = form.isOpen;
    final canSubmit = isOpen && (!hasSubmitted || form.settings.allowMultipleSubmissions);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getFormColor(form.accessibility).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFormIcon(form.accessibility),
                    color: _getFormColor(form.accessibility),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        form.accessibilityLabel,
                        style: TextStyle(
                          color: _getFormColor(form.accessibility),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Rempli',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (form.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                form.description,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Informations du formulaire
            Row(
              children: [
                Icon(
                  Icons.quiz,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${form.fields.length} questions',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                if (form.closeDate != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ferme le ${_formatDate(form.closeDate!)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
            
            if (form.hasSubmissionLimit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Limité à ${form.submissionLimit} réponses',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSubmit
                    ? () => _fillForm(form)
                    : null,
                icon: Icon(
                  canSubmit ? Icons.edit : Icons.lock,
                  size: 18,
                ),
                label: Text(
                  canSubmit
                      ? hasSubmitted ? 'Remplir à nouveau' : 'Remplir le formulaire'
                      : isOpen ? 'Déjà rempli' : 'Formulaire fermé',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit 
                      ? _getFormColor(form.accessibility) 
                      : AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(FormSubmissionModel submission) {
    final statusColor = _getSubmissionStatusColor(submission.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getSubmissionStatusIcon(submission.status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formulaire ID: ${submission.formId}', // TODO: Charger le titre du formulaire
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'Soumis le ${_formatDateTime(submission.submittedAt)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getSubmissionStatusLabel(submission.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Aperçu des réponses
            if (submission.responses.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu des réponses :',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...submission.responses.entries.take(3).map((entry) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${entry.key}: ${_truncateText(entry.value.toString(), 50)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                    if (submission.responses.length > 3)
                      Text(
                        '... et ${submission.responses.length - 3} autres réponses',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            if (submission.isTestSubmission) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.science,
                      size: 14,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Soumission',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getFormColor(String accessibility) {
    switch (accessibility) {
      case 'public':
        return AppTheme.successColor;
      case 'membres':
        return AppTheme.primaryColor;
      case 'groupe':
        return AppTheme.secondaryColor;
      case 'role':
        return AppTheme.tertiaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getFormIcon(String accessibility) {
    switch (accessibility) {
      case 'public':
        return Icons.public;
      case 'membres':
        return Icons.people;
      case 'groupe':
        return Icons.groups;
      case 'role':
        return Icons.badge;
      default:
        return Icons.assignment;
    }
  }

  Color _getSubmissionStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return AppTheme.primaryColor;
      case 'processed':
        return AppTheme.successColor;
      case 'archived':
        return AppTheme.textSecondaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getSubmissionStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.send;
      case 'processed':
        return Icons.check_circle;
      case 'archived':
        return Icons.archive;
      default:
        return Icons.help_outline;
    }
  }

  String _getSubmissionStatusLabel(String status) {
    switch (status) {
      case 'submitted':
        return 'Soumis';
      case 'processed':
        return 'Traité';
      case 'archived':
        return 'Archivé';
      default:
        return status;
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}