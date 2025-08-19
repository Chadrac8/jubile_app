import 'package:flutter/material.dart';
import '../models/form_model.dart';
import '../services/forms_firebase_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class FormResponsesList extends StatefulWidget {
  final FormModel form;

  const FormResponsesList({super.key, required this.form});

  @override
  State<FormResponsesList> createState() => _FormResponsesListState();
}

class _FormResponsesListState extends State<FormResponsesList>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _searchQuery = '';
  String _statusFilter = '';
  bool _showTestSubmissions = false;
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _statusFilters = {
    '': 'Tous les statuts',
    'submitted': 'Soumis',
    'processed': 'Traités',
    'archived': 'Archivés',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportResponses() async {
    try {
      final responses = await FormsFirebaseService.exportFormSubmissions(widget.form.id);
      
      if (!mounted) return;
      
      // TODO: Implement actual CSV export
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export de ${responses.length} réponses prêt'),
          backgroundColor: Theme.of(context).colorScheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor,
        ),
      );
    }
  }

  Future<void> _markAsProcessed(FormSubmissionModel submission) async {
    try {
      await FormsFirebaseService.updateSubmissionStatus(submission.id, 'processed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réponse marquée comme traitée'),
          backgroundColor: Theme.of(context).colorScheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.errorColor,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted': return Theme.of(context).colorScheme.warningColor;
      case 'processed': return Theme.of(context).colorScheme.successColor;
      case 'archived': return Theme.of(context).colorScheme.textTertiaryColor;
      default: return Theme.of(context).colorScheme.textSecondaryColor;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'submitted': return 'Soumis';
      case 'processed': return 'Traité';
      case 'archived': return 'Archivé';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildResponsesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.backgroundColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _exportResponses,
                icon: const Icon(Icons.download),
                label: const Text('Exporter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter.isEmpty ? null : _statusFilter,
                  onChanged: (value) => setState(() => _statusFilter = value ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusFilters.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key.isEmpty ? null : entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Inclure les tests'),
                  value: _showTestSubmissions,
                  onChanged: (value) => setState(() => _showTestSubmissions = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesList() {
    return StreamBuilder<List<FormSubmissionModel>>(
      stream: FormsFirebaseService.getFormSubmissionsStream(
        widget.form.id,
        statusFilter: _statusFilter.isNotEmpty ? _statusFilter : null,
        includeTestSubmissions: _showTestSubmissions,
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
                  color: Theme.of(context).colorScheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des réponses',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.textSecondaryColor,
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
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primaryColor),
            ),
          );
        }

        var submissions = snapshot.data ?? [];

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final queryLower = _searchQuery.toLowerCase();
          submissions = submissions.where((submission) =>
              submission.fullName.toLowerCase().contains(queryLower) ||
              (submission.email?.toLowerCase().contains(queryLower) ?? false)
          ).toList();
        }

        if (submissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune réponse trouvée',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.form.isPublished 
                      ? 'Les réponses apparaîtront ici une fois le formulaire soumis'
                      : 'Publiez le formulaire pour commencer à recevoir des réponses',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.textTertiaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: submissions.length,
          itemBuilder: (context, index) {
            final submission = submissions[index];
            return _buildSubmissionCard(submission);
          },
        );
      },
    );
  }

  Widget _buildSubmissionCard(FormSubmissionModel submission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showSubmissionDetails(submission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0x1A1976D2), // 10% opacity of primaryColor (#1976D2)
                    child: Text(
                      submission.fullName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (submission.email != null)
                          Text(
                            submission.email!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.textSecondaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(submission.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(submission.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(submission.submittedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Response preview
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu des réponses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      (submission.responses.length > 3 ? 3 : submission.responses.length),
                      (index) {
                        final entry = submission.responses.entries.elementAt(index);
                        final field = widget.form.fields.firstWhere(
                          (f) => f.id == entry.key,
                          orElse: () => CustomFormField(id: entry.key, type: 'text', label: 'Champ inconnu', order: 0),
                        );
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${field.label}:',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (submission.responses.length > 3)
                      Text(
                        '+${submission.responses.length - 3} autres réponses',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.textTertiaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Actions
              const SizedBox(height: 12),
              Row(
                children: [
                  if (submission.isTestSubmission)
                    Chip(
                      label: const Text('Test'),
                      backgroundColor: Color(0x1AFFA000), // 10% opacity of warningColor (#FFA000)
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.warningColor,
                        fontSize: 10,
                      ),
                    ),
                  const Spacer(),
                  if (!submission.isProcessed)
                    TextButton.icon(
                      onPressed: () => _markAsProcessed(submission),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Marquer comme traité'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.successColor,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _showSubmissionDetails(submission),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir détails'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmissionDetails(FormSubmissionModel submission) {
    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailsDialog(
        submission: submission,
        form: widget.form,
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

class _SubmissionDetailsDialog extends StatelessWidget {
  final FormSubmissionModel submission;
  final FormModel form;

  const _SubmissionDetailsDialog({
    required this.submission,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Theme.of(context).colorScheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails de la soumission',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Soumis par ${submission.fullName}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Submission info
                    _buildInfoSection('Informations générales', [
                      _buildInfoRow('Nom complet', submission.fullName),
                      if (submission.email != null)
                        _buildInfoRow('Email', submission.email!),
                      _buildInfoRow('Date de soumission', _formatDateTime(submission.submittedAt)),
                      _buildInfoRow('Statut', _getStatusLabel(submission.status)),
                      if (submission.isTestSubmission)
                        _buildInfoRow('Type', 'Soumission de test'),
                    ]),
                    
                    const SizedBox(height: 24),
                    
                    // Responses
                    _buildInfoSection('Réponses au formulaire', [
                      ...List.generate(form.fields.length, (index) {
                        final field = form.fields[index];
                        if (!field.isInputField) return const SizedBox.shrink();
                        
                        final response = submission.responses[field.id];
                        return _buildInfoRow(
                          field.label,
                          response?.toString() ?? 'Pas de réponse',
                        );
                      }),
                    ]),
                    
                    // Files
                    if (submission.fileUrls.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildInfoSection('Fichiers joints', [
                        ...List.generate(submission.fileUrls.length, (index) {
                          // fileUrl variable removed as it was unused
                          return ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text('Fichier ${index + 1}'),
                            trailing: const Icon(Icons.download),
                            onTap: () {
                              // TODO: Download file
                            },
                          );
                        }),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Theme.of(context).colorScheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'submitted': return 'Soumis';
      case 'processed': return 'Traité';
      case 'archived': return 'Archivé';
      default: return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}