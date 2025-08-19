import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:flutter/services.dart';
import '../models/home_cover_config_model.dart';
import '../services/home_cover_config_service.dart';

/// Page d'administration pour configurer l'image de couverture de l'accueil membre
class HomeCoverAdminPage extends StatefulWidget {
  const HomeCoverAdminPage({super.key});

  @override
  State<HomeCoverAdminPage> createState() => _HomeCoverAdminPageState();
}

class _HomeCoverAdminPageState extends State<HomeCoverAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _imageUrlController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _useVideo = false;
  HomeCoverConfigModel? _currentConfig;
  String? _previewImageUrl;
  
  // Variables pour gérer la liste d'images
  List<String> _imageUrls = [];
  final _newImageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _videoUrlController.dispose();
    _newImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await HomeCoverConfigService.getActiveCoverConfig();
      setState(() {
        _currentConfig = config;
        _imageUrlController.text = config.coverImageUrl;
        _titleController.text = config.coverTitle ?? '';
        _subtitleController.text = config.coverSubtitle ?? '';
        _videoUrlController.text = config.coverVideoUrl ?? '';
        _useVideo = config.useVideo;
        _previewImageUrl = config.coverImageUrl;
        _imageUrls = List<String>.from(config.coverImageUrls);
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement de la configuration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addImageUrl() {
    final url = _newImageUrlController.text.trim();
    if (url.isNotEmpty && !_imageUrls.contains(url)) {
      setState(() {
        _imageUrls.add(url);
        _newImageUrlController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _imageUrls.removeAt(oldIndex);
      _imageUrls.insert(newIndex, item);
    });
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await HomeCoverConfigService.updateCoverConfig(
        coverImageUrl: _useVideo ? '' : _imageUrlController.text.trim(),
        coverImageUrls: _useVideo ? [] : _imageUrls,
        coverTitle: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        coverSubtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        coverVideoUrl: _useVideo ? _videoUrlController.text.trim() : null,
        useVideo: _useVideo);
      
      _showSuccessSnackBar('Configuration sauvegardée avec succès');
      await _loadCurrentConfig();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await _showConfirmDialog(
      'Réinitialiser la configuration',
      'Êtes-vous sûr de vouloir réinitialiser la configuration aux valeurs par défaut ?');
    
    if (!confirmed) return;

    setState(() => _isSaving = true);
    try {
      await HomeCoverConfigService.resetToDefault();
      _showSuccessSnackBar('Configuration réinitialisée aux valeurs par défaut');
      await _loadCurrentConfig();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la réinitialisation: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _previewImage() {
    final url = _imageUrlController.text.trim();
    if (HomeCoverConfigService.isValidImageUrl(url)) {
      setState(() => _previewImageUrl = url);
    } else {
      _showErrorSnackBar('URL d\'image invalide');
    }
  }

  void _selectSuggestedImage(String imageUrl) {
    _imageUrlController.text = imageUrl;
    setState(() => _previewImageUrl = imageUrl);
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer')),
        ])) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Image de Couverture'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _resetToDefault,
            icon: const Icon(Icons.restore),
            tooltip: 'Réinitialiser aux valeurs par défaut'),
        ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentConfigCard(),
                    const SizedBox(height: 24),
                    _buildImageConfigurationSection(),
                    const SizedBox(height: 24),
                    _buildTextConfigurationSection(),
                    const SizedBox(height: 24),
                    _buildImageSuggestionsSection(),
                    const SizedBox(height: 24),
                    _buildPreviewSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ]))));
  }

  Widget _buildCurrentConfigCard() {
    if (_currentConfig == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Configuration Actuelle',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700)),
              ]),
            const SizedBox(height: 12),
            _buildInfoRow('Dernière modification', 
                _formatDate(_currentConfig!.updatedAt)),
            if (_currentConfig!.coverTitle != null)
              _buildInfoRow('Titre', _currentConfig!.coverTitle!),
            if (_currentConfig!.coverSubtitle != null)
              _buildInfoRow('Sous-titre', _currentConfig!.coverSubtitle!),
          ])));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textTertiaryColor))),
        ]));
  }

  Widget _buildImageConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Configuration de la Couverture',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            
            // Toggle entre vidéo et image
            SwitchListTile(
              title: const Text(
                'Utiliser une vidéo',
                style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _useVideo 
                    ? 'La couverture affichera une vidéo en arrière-plan'
                    : 'La couverture affichera un carrousel d\'images',
                style: TextStyle(color: AppTheme.textTertiaryColor)),
              value: _useVideo,
              onChanged: (value) {
                setState(() {
                  _useVideo = value;
                });
              },
              activeColor: AppTheme.primaryColor),
            
            const SizedBox(height: 16),
            
            if (_useVideo) ...[
              // Configuration vidéo
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de la vidéo',
                  hintText: 'https://example.com/video.mp4',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_library)),
                validator: (value) {
                  if (value != null && value.isNotEmpty && !Uri.tryParse(value)!.isAbsolute) {
                    return 'URL de vidéo invalide';
                  }
                  return null;
                },
                maxLines: 2),
              const SizedBox(height: 8),
              Text(
                'Formats supportés: MP4, MOV, AVI',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiaryColor)),
            ] else ...[
              // Configuration image principale
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'URL de l\'image de couverture',
                  hintText: 'https://example.com/image.jpg',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _previewImage,
                        icon: const Icon(Icons.visibility),
                        tooltip: 'Prévisualiser'),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _imageUrlController.text));
                          _showSuccessSnackBar('URL copiée dans le presse-papiers');
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copier'),
                    ])),
                validator: (value) {
                  if (!_useVideo && (value == null || value.trim().isEmpty)) {
                    return 'L\'URL de l\'image est requise';
                  }
                  if (!_useVideo && value != null && value.isNotEmpty && !HomeCoverConfigService.isValidImageUrl(value.trim())) {
                    return 'URL d\'image invalide';
                  }
                  return null;
                },
                maxLines: 2),
              const SizedBox(height: 8),
              Text(
                'Formats supportés: JPG, JPEG, PNG, WebP, GIF',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textTertiaryColor)),
            ],
          ])));
  }

  Widget _buildTextConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Textes de Couverture',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre (optionnel)',
                hintText: 'Bienvenue dans notre communauté',
                border: OutlineInputBorder()),
              maxLength: 100),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Sous-titre (optionnel)',
                hintText: 'Ensemble, nous grandissons dans la foi',
                border: OutlineInputBorder()),
              maxLength: 150,
              maxLines: 2),
            const SizedBox(height: 24),
            _buildImageCarouselSection(),
          ])));
  }

  Widget _buildImageCarouselSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_carousel, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Images du Carrousel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez plusieurs images qui défileront automatiquement sur la page d\'accueil.',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiaryColor)),
            const SizedBox(height: 16),
            
            // Section pour ajouter une nouvelle image
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newImageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL de l\'image',
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(),
                      isDense: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && !Uri.tryParse(value)!.isAbsolute) {
                        return 'URL invalide';
                      }
                      return null;
                    })),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addImageUrl,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: AppTheme.surfaceColor)),
              ]),
            
            const SizedBox(height: 16),
            
            // Liste des images
            if (_imageUrls.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.textTertiaryColor),
                  borderRadius: BorderRadius.circular(8)),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported_outlined, 
                           size: 48, color: AppTheme.textTertiaryColor),
                      SizedBox(height: 8),
                      Text('Aucune image ajoutée',
                           style: TextStyle(color: AppTheme.textTertiaryColor)),
                    ])))
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  itemCount: _imageUrls.length,
                  onReorder: _reorderImages,
                  itemBuilder: (context, index) {
                    final imageUrl = _imageUrls[index];
                    return Card(
                      key: ValueKey(imageUrl),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.textTertiaryColor)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.textTertiaryColor,
                                  child: const Icon(Icons.broken_image));
                              }))),
                        title: Text(
                          imageUrl,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                        subtitle: Text('Image ${index + 1}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_handle, color: AppTheme.textTertiaryColor),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.delete, color: AppTheme.errorColor),
                              onPressed: () => _removeImageUrl(index),
                              tooltip: 'Supprimer'),
                          ])));
                  })),
          ])));
  }

  Widget _buildImageSuggestionsSection() {
    final suggestions = HomeCoverConfigService.getDefaultImageSuggestions();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Images Suggérées',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final imageUrl = suggestions[index];
                  return GestureDetector(
                    onTap: () => _selectSuggestedImage(imageUrl),
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _imageUrlController.text == imageUrl
                              ? Colors.deepPurple
                              : AppTheme.textTertiaryColor,
                          width: 2)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.textTertiaryColor,
                              child: const Icon(Icons.broken_image));
                          }))));
                })),
          ])));
  }

  Widget _buildPreviewSection() {
    if (_previewImageUrl == null || _previewImageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Aperçu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.textTertiaryColor)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.network(
                      _previewImageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.textTertiaryColor,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48),
                                SizedBox(height: 8),
                                Text('Impossible de charger l\'image'),
                              ])));
                      }),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ]))),
                    if (_titleController.text.isNotEmpty || _subtitleController.text.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_titleController.text.isNotEmpty)
                              Text(
                                _titleController.text,
                                style: const TextStyle(
                                  color: AppTheme.surfaceColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                            if (_subtitleController.text.isNotEmpty)
                              Text(
                                _subtitleController.text,
                                style: const TextStyle(
                                  color: AppTheme.surfaceColor,
                                  fontSize: 14)),
                          ])),
                  ]))),
          ])));
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'))),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveConfiguration,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: AppTheme.surfaceColor),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Text('Sauvegarder'))),
      ]);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
