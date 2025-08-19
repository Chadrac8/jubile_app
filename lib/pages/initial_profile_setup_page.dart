import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_model.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;

class InitialProfileSetupPage extends StatefulWidget {
  const InitialProfileSetupPage({super.key});

  @override
  State<InitialProfileSetupPage> createState() => _InitialProfileSetupPageState();
}

class _InitialProfileSetupPageState extends State<InitialProfileSetupPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Form values
  DateTime? _birthDate;
  String? _gender;
  String? _profileImageUrl;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _prefillFromAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _prefillFromAuth() {
    final user = AuthService.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        final nameParts = user.displayName!.trim().split(' ');
        _firstNameController.text = nameParts.first;
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.skip(1).join(' ');
        }
      }
      
      if (user.photoURL != null) {
        _profileImageUrl = user.photoURL;
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes != null) {
        // Sauvegarder l'ancienne URL pour la supprimer après upload réussi
        final oldImageUrl = _profileImageUrl;
        
        // Upload to Firebase Storage instead of storing as base64
        final imageUrl = await ImageStorage.ImageStorageService.uploadImage(
          imageBytes,
          customPath: 'profiles/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        if (imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
          
          // Supprimer l'ancienne image si elle existe et est stockée sur Firebase
          if (oldImageUrl != null && 
              oldImageUrl.isNotEmpty && 
              ImageStorage.ImageStorageService.isFirebaseStorageUrl(oldImageUrl)) {
            ImageStorage.ImageStorageService.deleteImageByUrl(oldImageUrl);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Image de profil mise à jour avec succès'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } else {
          throw Exception('Échec de l\'upload de l\'image vers Firebase Storage');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Get current profile
      final currentProfile = await AuthService.getCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('Profil utilisateur non trouvé');
      }

      // Update profile with additional info
      final updatedProfile = currentProfile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        birthDate: _birthDate,
        gender: _gender,
        profileImageUrl: _profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await AuthService.updateCurrentUserProfile(updatedProfile);

      if (mounted) {
        // Navigate to main app
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la configuration: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  void _skipSetup() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primaryColor,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Configuration du profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryColor,
                          Theme.of(context).colorScheme.secondaryColor,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_add,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(),
                        const SizedBox(height: 24),
                        _buildForm(),
                        const SizedBox(height: 32),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.waving_hand,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue !',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complétez votre profil pour personnaliser votre expérience.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.textSecondaryColor,
                        ),
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileImageSection(),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone (optionnel)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildDateField(),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _gender,
                label: 'Genre (optionnel)',
                icon: Icons.person_2,
                items: _genderOptions,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primaryColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _profileImageUrl != null
                    ? (_profileImageUrl!.startsWith('data:')
                        ? Image.memory(
                            base64Decode(_profileImageUrl!.split(',')[1]),
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: _profileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => _buildFallbackAvatar(),
                          ))
                    : _buildFallbackAvatar(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _pickProfileImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Changer la photo'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).colorScheme.primaryColor,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Theme.of(context).colorScheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primaryColor, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectBirthDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _birthDate != null
                    ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                    : 'Date de naissance (optionnel)',
                style: TextStyle(
                  color: _birthDate != null
                      ? Theme.of(context).colorScheme.textPrimaryColor
                      : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primaryColor, width: 2),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _completeSetup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Terminer la configuration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _skipSetup,
          child: Text(
            'Ignorer pour l\'instant',
            style: TextStyle(
              color: Theme.of(context).colorScheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}