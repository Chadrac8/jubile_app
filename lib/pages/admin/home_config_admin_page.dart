import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/home_config_model.dart';
import '../../services/home_config_service.dart';
import '../../services/image_upload_service.dart';
import '../../compatibility/app_theme_bridge.dart';

class HomeConfigAdminPage extends StatefulWidget {
  const HomeConfigAdminPage({super.key});

  @override
  State<HomeConfigAdminPage> createState() => _HomeConfigAdminPageState();
}

class _HomeConfigAdminPageState extends State<HomeConfigAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _versetController = TextEditingController();
  final _referenceController = TextEditingController();
  final _sermonTitleController = TextEditingController();
  final _sermonUrlController = TextEditingController();
  
  HomeConfigModel? _homeConfig;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _newCoverImageUrl;

  @override
  void initState() {
    super.initState();
    _loadHomeConfig();
  }

  @override
  void dispose() {
    _versetController.dispose();
    _referenceController.dispose();
    _sermonTitleController.dispose();
    _sermonUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeConfig() async {
    try {
      final config = await HomeConfigService.getHomeConfig();
      
      setState(() {
        _homeConfig = config;
        _versetController.text = config.versetDuJour;
        _referenceController.text = config.versetReference;
        _sermonTitleController.text = config.sermonTitle;
        _sermonUrlController.text = config.sermonYouTubeUrl ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor));
      }
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85);

      if (image != null) {
        setState(() {
          _isSaving = true;
        });

        // Upload de l'image
        final imageUrl = await ImageUploadService.uploadImage(
          file: File(image.path),
          folder: 'home_config/cover_images');

        setState(() {
          _newCoverImageUrl = imageUrl;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image de couverture mise à jour avec succès'),
            backgroundColor: Theme.of(context).colorScheme.successColor));
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor));
      }
    }
  }

  Future<void> _addTestImage() async {
    try {
      setState(() {
        _isSaving = true;
      });

      // URL d'une image de test (église)
      const testImageUrl = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1200&q=80';

      setState(() {
        _newCoverImageUrl = testImageUrl;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image de test ajoutée. Cliquez sur "Sauvegarder" pour confirmer.'),
          backgroundColor: Theme.of(context).colorScheme.warningColor));
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'image de test: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor));
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final coverImageToSave = _newCoverImageUrl ?? _homeConfig!.coverImageUrl;
      
      final updatedConfig = _homeConfig!.copyWith(
        versetDuJour: _versetController.text,
        versetReference: _referenceController.text,
        sermonTitle: _sermonTitleController.text.isEmpty ? null : _sermonTitleController.text,
        sermonYouTubeUrl: _sermonUrlController.text.isEmpty ? null : _sermonUrlController.text,
        coverImageUrl: coverImageToSave,
        lastUpdated: DateTime.now());

      await HomeConfigService.updateHomeConfig(updatedConfig);

      setState(() {
        _homeConfig = updatedConfig;
        _newCoverImageUrl = null;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sauvegardée avec succès'),
            backgroundColor: Theme.of(context).colorScheme.successColor));
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor));
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false);
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuration Accueil')),
        body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Accueil'),
        backgroundColor: Theme.of(context).colorScheme.primaryColor,
        foregroundColor: Theme.of(context).colorScheme.surfaceColor,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white))))
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveConfiguration),
        ]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image de couverture
              _buildCoverImageSection(),
              const SizedBox(height: 32),

              // Section Verset du jour
              _buildDailyVerseSection(),
              const SizedBox(height: 32),

              // Section Sermon
              _buildSermonSection(),
              const SizedBox(height: 32),

              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveConfiguration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                            SizedBox(width: 12),
                            Text('Sauvegarde en cours...'),
                          ])
                      : const Text(
                          'Sauvegarder la configuration',
                          style: TextStyle(fontSize: 16)))),
              
              // Widget de diagnostic (temporaire)
              const SizedBox(height: 24),
              _buildDiagnosticWidget(),
            ]))));
  }

  Widget _buildCoverImageSection() {
    final currentImageUrl = _newCoverImageUrl ?? _homeConfig?.coverImageUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Image de couverture',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            
            // Aperçu de l'image actuelle
            if (currentImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    currentImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Theme.of(context).colorScheme.textTertiaryColor,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.textTertiaryColor),
                              const SizedBox(height: 8),
                              Text(
                                'Erreur: $error',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.errorColor),
                                textAlign: TextAlign.center),
                            ])));
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null));
                    }))),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.textTertiaryColor)),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Theme.of(context).colorScheme.textTertiaryColor),
                      SizedBox(height: 8),
                      Text(
                        'Aucune image de couverture',
                        style: TextStyle(color: Theme.of(context).colorScheme.textTertiaryColor)),
                    ]))),
              const SizedBox(height: 16),
            ],

            // Bouton pour changer l'image
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickCoverImage,
                icon: const Icon(Icons.photo_camera),
                label: Text(
                  currentImageUrl != null 
                      ? 'Changer l\'image de couverture'
                      : 'Ajouter une image de couverture'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primaryColor,
                  side: BorderSide(color: Theme.of(context).colorScheme.primaryColor)))),
            const SizedBox(height: 12),
            
            // Bouton de test avec image par défaut
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _addTestImage,
                icon: const Icon(Icons.image),
                label: const Text('Ajouter une image de test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.warningColor,
                  foregroundColor: Theme.of(context).colorScheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 12)))),
          ])));
  }

  Widget _buildDailyVerseSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Verset du jour',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _versetController,
              decoration: const InputDecoration(
                labelText: 'Texte du verset',
                hintText: 'Entrez le texte du verset...',
                border: OutlineInputBorder()),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le texte du verset est obligatoire';
                }
                return null;
              }),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence biblique',
                hintText: 'Ex: Jean 3:16',
                border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La référence biblique est obligatoire';
                }
                return null;
              }),
          ])));
  }

  Widget _buildSermonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle,
                  color: Theme.of(context).colorScheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Dernière prédication',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold)),
              ]),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _sermonTitleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la prédication',
                hintText: 'Entrez le titre...',
                border: OutlineInputBorder())),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _sermonUrlController,
              decoration: const InputDecoration(
                labelText: 'URL YouTube',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.video_library)),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final videoId = _extractYouTubeVideoId(value);
                  if (videoId == null) {
                    return 'URL YouTube invalide';
                  }
                }
                return null;
              }),
            const SizedBox(height: 8),
            Text(
              'Formats acceptés: youtube.com/watch?v=... ou youtu.be/...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.textTertiaryColor)),
            
            // Aperçu vidéo si URL valide
            if (_sermonUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final videoId = _extractYouTubeVideoId(_sermonUrlController.text);
                  if (videoId != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aperçu:',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).colorScheme.textTertiaryColor,
                                  child: const Center(
                                    child: Icon(Icons.error_outline)));
                              }))),
                      ]);
                  }
                  return const SizedBox.shrink();
                }),
            ],

            const SizedBox(height: 16),
            
            // Bouton pour sélectionner une vidéo YouTube
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showYouTubePicker(),
                icon: const Icon(Icons.search),
                label: const Text('Rechercher une vidéo YouTube'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primaryColor,
                  side: BorderSide(color: Theme.of(context).colorScheme.primaryColor)))),
          ])));
  }

  void _showYouTubePicker() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Recherche YouTube', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _sermonUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL YouTube',
                  hintText: 'https://www.youtube.com/watch?v=...')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Confirmer')),
            ]))));
  }

  Widget _buildDiagnosticWidget() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Diagnostic - Configuration Admin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700])),
              ]),
            const SizedBox(height: 12),
            _buildDiagnosticRow('ID Config', _homeConfig?.id ?? 'NULL'),
            _buildDiagnosticRow('Cover Image URL', _homeConfig?.coverImageUrl ?? 'NULL'),
            _buildDiagnosticRow('New Cover Image URL', _newCoverImageUrl ?? 'NULL'),
            _buildDiagnosticRow('Current Display URL', _newCoverImageUrl ?? _homeConfig?.coverImageUrl ?? 'NULL'),
            _buildDiagnosticRow('Verset du Jour', _homeConfig?.versetDuJour ?? 'NULL'),
            _buildDiagnosticRow('Sermon Title', _homeConfig?.sermonTitle ?? 'NULL'),
            _buildDiagnosticRow('Sermon YouTube URL', _homeConfig?.sermonYouTubeUrl ?? 'NULL'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  (_homeConfig?.coverImageUrl != null && _homeConfig!.coverImageUrl!.isNotEmpty) 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: (_homeConfig?.coverImageUrl != null && _homeConfig!.coverImageUrl!.isNotEmpty) 
                      ? Theme.of(context).colorScheme.successColor 
                      : Theme.of(context).colorScheme.errorColor),
                const SizedBox(width: 8),
                Text(
                  (_homeConfig?.coverImageUrl != null && _homeConfig!.coverImageUrl!.isNotEmpty) 
                      ? 'Image de couverture configurée'
                      : 'Aucune image de couverture',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (_homeConfig?.coverImageUrl != null && _homeConfig!.coverImageUrl!.isNotEmpty) 
                        ? Theme.of(context).colorScheme.successColor 
                        : Theme.of(context).colorScheme.errorColor)),
              ]),
          ])));
  }

  Widget _buildDiagnosticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: Text(
              value.length > 50 ? '${value.substring(0, 50)}...' : value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: value == 'NULL' ? Theme.of(context).colorScheme.errorColor : Colors.black87))),
        ]));
  }
}
