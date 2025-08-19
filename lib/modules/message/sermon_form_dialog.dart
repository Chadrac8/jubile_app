import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/admin_branham_sermon_model.dart';
import '../services/admin_branham_sermon_service.dart';
import '../../../auth/auth_service.dart';

/// Dialogue pour ajouter/modifier une prédication
class SermonFormDialog extends StatefulWidget {
  final AdminBranhamSermon? sermon;
  final Function(AdminBranhamSermon) onSaved;

  const SermonFormDialog({
    Key? key,
    this.sermon,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<SermonFormDialog> createState() => _SermonFormDialogState();
}

class _SermonFormDialogState extends State<SermonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _audioDownloadUrlController = TextEditingController();
  final _pdfUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _seriesController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _displayOrderController = TextEditingController();
  
  int _durationHours = 0;
  int _durationMinutes = 0;
  String _language = 'fr';
  bool _isActive = true;
  bool _isLoading = false;
  bool _isValidatingUrl = false;

  @override
  void initState() {
    super.initState();
    if (widget.sermon != null) {
      _populateFields(widget.sermon!);
    }
  }

  void _populateFields(AdminBranhamSermon sermon) {
    _titleController.text = sermon.title;
    _dateController.text = sermon.date;
    _locationController.text = sermon.location;
    _audioUrlController.text = sermon.audioUrl;
    _audioDownloadUrlController.text = sermon.audioDownloadUrl ?? '';
    _pdfUrlController.text = sermon.pdfUrl ?? '';
    _imageUrlController.text = sermon.imageUrl ?? '';
    _descriptionController.text = sermon.description ?? '';
    _seriesController.text = sermon.series ?? '';
    _keywordsController.text = sermon.keywords.join(', ');
    _displayOrderController.text = sermon.displayOrder.toString();
    
    if (sermon.duration != null) {
      _durationHours = sermon.duration!.inHours;
      _durationMinutes = sermon.duration!.inMinutes % 60;
    }
    
    _language = sermon.language;
    _isActive = sermon.isActive;
  }

  Future<void> _validateAudioUrl() async {
    if (_audioUrlController.text.isEmpty) return;
    
    setState(() => _isValidatingUrl = true);
    
    final isValid = await AdminBranhamSermonService.validateAudioUrl(
      _audioUrlController.text
    );
    
    setState(() => _isValidatingUrl = false);
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL audio invalide'),
          backgroundColor: AppTheme.warningColor));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL audio valide'),
          backgroundColor: AppTheme.successColor));
    }
  }

  Future<void> _saveSermon() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = AuthService.currentUser;
      final keywords = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
      
      final duration = Duration(
        hours: _durationHours,
        minutes: _durationMinutes);
      
      final sermon = AdminBranhamSermon(
        id: widget.sermon?.id ?? '',
        title: _titleController.text.trim(),
        date: _dateController.text.trim(),
        location: _locationController.text.trim(),
        audioUrl: _audioUrlController.text.trim(),
        audioDownloadUrl: _audioDownloadUrlController.text.trim().isEmpty 
            ? null 
            : _audioDownloadUrlController.text.trim(),
        pdfUrl: _pdfUrlController.text.trim().isEmpty 
            ? null 
            : _pdfUrlController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty 
            ? null 
            : _imageUrlController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        duration: duration.inMinutes > 0 ? duration : null,
        language: _language,
        series: _seriesController.text.trim().isEmpty 
            ? null 
            : _seriesController.text.trim(),
        keywords: keywords,
        createdAt: widget.sermon?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: widget.sermon?.createdBy ?? currentUser?.uid,
        isActive: _isActive,
        displayOrder: int.tryParse(_displayOrderController.text) ?? 0);
      
      bool success;
      if (widget.sermon == null) {
        // Nouvelle prédication
        final id = await AdminBranhamSermonService.addSermon(sermon);
        success = id != null;
      } else {
        // Modification
        success = await AdminBranhamSermonService.updateSermon(
          widget.sermon!.id,
          sermon);
      }
      
      if (success) {
        widget.onSaved(sermon);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.sermon == null 
                ? 'Prédication ajoutée avec succès' 
                : 'Prédication modifiée avec succès'),
            backgroundColor: AppTheme.successColor));
      } else {
        throw Exception('Échec de la sauvegarde');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // En-tête
            Row(
              children: [
                Text(
                  widget.sermon == null 
                      ? 'Ajouter une Prédication' 
                      : 'Modifier la Prédication',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
              ]),
            const Divider(),
            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Informations de base
                      _buildSectionTitle('Informations de base'),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Titre de la prédication',
                        required: true,
                        icon: Icons.title),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _dateController,
                              label: 'Date (ex: 47-0412)',
                              required: true,
                              icon: Icons.calendar_today,
                              hint: 'Format: AA-MMJJ')),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _locationController,
                              label: 'Lieu',
                              required: true,
                              icon: Icons.location_on,
                              hint: 'ex: Jeffersonville, IN')),
                        ]),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 3),
                      
                      // URLs et fichiers
                      const SizedBox(height: 24),
                      _buildSectionTitle('Fichiers multimédia'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _audioUrlController,
                              label: 'URL Audio (streaming)',
                              required: true,
                              icon: Icons.audiotrack,
                              hint: 'https://example.com/audio.mp3')),
                          const SizedBox(width: 8),
                          if (_isValidatingUrl)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            IconButton(
                              icon: const Icon(Icons.check_circle),
                              onPressed: _validateAudioUrl,
                              tooltip: 'Valider l\'URL'),
                        ]),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _audioDownloadUrlController,
                        label: 'URL de téléchargement (optionnel)',
                        icon: Icons.download),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _pdfUrlController,
                        label: 'URL PDF (optionnel)',
                        icon: Icons.picture_as_pdf),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _imageUrlController,
                        label: 'URL Image (optionnel)',
                        icon: Icons.image),
                      
                      // Métadonnées
                      const SizedBox(height: 24),
                      _buildSectionTitle('Métadonnées'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _seriesController,
                              label: 'Série (optionnel)',
                              icon: Icons.list)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _language,
                              decoration: const InputDecoration(
                                labelText: 'Langue',
                                prefixIcon: Icon(Icons.language),
                                border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'fr', child: Text('Français')),
                                DropdownMenuItem(value: 'en', child: Text('Anglais')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _language = value);
                                }
                              })),
                        ]),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _keywordsController,
                        label: 'Mots-clés (séparés par des virgules)',
                        icon: Icons.label,
                        hint: 'foi, baptême, guérison'),
                      
                      // Durée et paramètres
                      const SizedBox(height: 24),
                      _buildSectionTitle('Configuration'),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Durée',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _durationHours.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Heures',
                                          border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          _durationHours = int.tryParse(value) ?? 0;
                                        })),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _durationMinutes.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Minutes',
                                          border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          _durationMinutes = int.tryParse(value) ?? 0;
                                        })),
                                  ]),
                              ])),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _displayOrderController,
                                  label: 'Ordre d\'affichage',
                                  icon: Icons.sort,
                                  keyboardType: TextInputType.number,
                                  hint: '0'),
                                const SizedBox(height: 16),
                                SwitchListTile(
                                  title: const Text('Prédication active'),
                                  subtitle: const Text('Visible dans l\'onglet Écouter'),
                                  value: _isActive,
                                  onChanged: (value) {
                                    setState(() => _isActive = value);
                                  }),
                              ])),
                        ]),
                    ])))),
            
            // Boutons d'action
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSermon,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.sermon == null ? 'Ajouter' : 'Modifier')),
              ]),
          ])));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppTheme.primaryColor.withOpacity(0.3))),
        ]));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder()),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label est requis';
              }
              return null;
            }
          : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _audioUrlController.dispose();
    _audioDownloadUrlController.dispose();
    _pdfUrlController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _seriesController.dispose();
    _keywordsController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }
}
