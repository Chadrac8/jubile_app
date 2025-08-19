import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart';
import '../theme.dart';
import 'image_gallery_widget.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialUrl;
  final Function(String?) onImageSelected;
  final double? height;
  final String? label;
  final bool isRequired;

  const ImagePickerWidget({
    super.key,
    this.initialUrl,
    required this.onImageSelected,
    this.height = 200,
    this.label = 'Image',
    this.isRequired = false,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final _urlController = TextEditingController();
  String? _currentImageUrl;
  bool _isUploading = false;
  String _selectionMode = 'url'; // 'url', 'upload' ou 'gallery'

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialUrl;
    _urlController.text = widget.initialUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onImageUrlChanged(String url) {
    setState(() {
      _currentImageUrl = url.trim().isEmpty ? null : url.trim();
    });
    widget.onImageSelected(_currentImageUrl);
  }

  Future<void> _pickImageFromGallery() async {
    setState(() => _isUploading = true);

    try {
      final imageData = await ImageUploadHelper.pickImageFromGallery();
      
      if (imageData != null) {
        // Upload vers Firebase Storage
        final imageUrl = await ImageStorageService.uploadImage(
          imageData,
          fileName: 'page_component_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (imageUrl != null) {
          setState(() {
            _currentImageUrl = imageUrl;
            _urlController.text = imageUrl;
          });
          widget.onImageSelected(imageUrl);
          
          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploadée avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _captureImageFromCamera() async {
    setState(() => _isUploading = true);

    try {
      final imageData = await ImageUploadHelper.captureImage();
      
      if (imageData != null) {
        // Upload vers Firebase Storage
        final imageUrl = await ImageStorageService.uploadImage(
          imageData,
          fileName: 'page_component_camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (imageUrl != null) {
          setState(() {
            _currentImageUrl = imageUrl;
            _urlController.text = imageUrl;
          });
          widget.onImageSelected(imageUrl);
          
          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo capturée et uploadée avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _currentImageUrl = null;
      _urlController.clear();
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Titre et mode de sélection
        Row(
          children: [
            Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
            const Spacer(),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'url',
                  label: Text('URL'),
                  icon: Icon(Icons.link, size: 16),
                ),
                ButtonSegment(
                  value: 'upload',
                  label: Text('Upload'),
                  icon: Icon(Icons.upload, size: 16),
                ),
                ButtonSegment(
                  value: 'gallery',
                  label: Text('Mes images'),
                  icon: Icon(Icons.photo_library, size: 16),
                ),
              ],
              selected: {_selectionMode},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectionMode = selection.first;
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),

        // Interface selon le mode sélectionné
        if (_selectionMode == 'url') ...[
          // Saisie URL
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'URL de l\'image',
              border: const OutlineInputBorder(),
              helperText: 'URL complète vers l\'image (ex: https://example.com/image.jpg)',
              suffixIcon: _currentImageUrl != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _removeImage,
                    )
                  : null,
            ),
            onChanged: _onImageUrlChanged,
            validator: widget.isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'URL de l\'image est requise';
                    }
                    return null;
                  }
                : null,
          ),
        ] else if (_selectionMode == 'upload') ...[
          // Boutons pour sélection depuis galerie/caméra
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choisir de la galerie'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _captureImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Prendre une photo'),
                ),
              ),
            ],
          ),
          
          if (_currentImageUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Image sélectionnée',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ] else if (_selectionMode == 'gallery') ...[
          // Galerie d'images existantes
          ImageGalleryWidget(
            selectedImageUrl: _currentImageUrl,
            onImageSelected: (imageUrl) {
              setState(() {
                _currentImageUrl = imageUrl;
                _urlController.text = imageUrl;
              });
              widget.onImageSelected(imageUrl);
            },
          ),
        ],

        // Indicateur de chargement
        if (_isUploading) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Upload en cours...'),
              ],
            ),
          ),
        ],

        // Prévisualisation de l'image
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _currentImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}