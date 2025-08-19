import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_model.dart';
import '../models/role_model.dart';
import '../services/firebase_service.dart';
import '../services/user_profile_service.dart';
import '../services/roles_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';
import '../widgets/custom_page_app_bar.dart';
import '../extensions/datetime_extensions.dart';

import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;

class MemberProfilePage extends StatefulWidget {
  final PersonModel? person;

  const MemberProfilePage({super.key, this.person});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  PersonModel? _currentPerson;
  FamilyModel? _family;
  List<PersonModel> _familyMembers = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  DateTime? _birthDate;
  String? _gender;
  String? _maritalStatus;
  String? _profileImageUrl;
  bool _hasImageChanged = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPersonData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _loadPersonData() async {
    try {
      setState(() => _isLoading = true);
      
      // Charger le profil de l'utilisateur connecté
      PersonModel? person = await AuthService.getCurrentUserProfile();

      if (person == null) {
        // Fallback: essayer de créer le profil depuis Firebase Auth
        final user = AuthService.currentUser;
        if (user != null) {
          print('Tentative de création du profil pour ${user.uid}');
          await UserProfileService.ensureUserProfile(user);
          person = await AuthService.getCurrentUserProfile();
        }
      }

      if (person != null) {
        setState(() {
          _currentPerson = person;
          _initializeForm();
        });

        // Charger la famille si elle existe
        if (person.familyId != null) {
          try {
            final family = await FirebaseService.getFamily(person.familyId!);
            if (family != null) {
              setState(() {
                _family = family;
              });
              await _loadFamilyMembers();
            }
          } catch (e) {
            print('Erreur chargement famille: $e');
          }
        }

        // Charger les rôles
        await _loadRoles();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de charger votre profil'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement profil: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _initializeForm() {
    if (_currentPerson != null) {
      _firstNameController.text = _currentPerson!.firstName;
      _lastNameController.text = _currentPerson!.lastName;
      _emailController.text = _currentPerson!.email;
      _phoneController.text = _currentPerson!.phone ?? '';
      _addressController.text = _currentPerson!.address ?? '';
      _birthDate = _currentPerson!.birthDate;
      _gender = _currentPerson!.gender;
      _maritalStatus = _currentPerson!.maritalStatus;
      _profileImageUrl = _currentPerson!.profileImageUrl;
    }
  }

  Future<void> _loadFamilyMembers() async {
    if (_family == null) return;

    try {
      final members = <PersonModel>[];
      for (final memberId in _family!.memberIds) {
        final member = await FirebaseService.getPerson(memberId);
        if (member != null) {
          members.add(member);
        }
      }
      setState(() {
        _familyMembers = members;
      });
    } catch (e) {
      print('Erreur chargement famille: $e');
    }
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await RolesFirebaseService.getRolesStream(activeOnly: true).first;
      setState(() {
        _roles = roles;
      });
    } catch (e) {
      print('Erreur chargement rôles: $e');
    }
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _birthDate = date;
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
            _hasImageChanged = true;
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
            content: Text('Erreur lors de la sélection de l\'image : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_currentPerson == null) return;

    try {
      final updatedPerson = _currentPerson!.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        birthDate: _birthDate,
        gender: _gender,
        maritalStatus: _maritalStatus,
        profileImageUrl: _profileImageUrl,
        updatedAt: DateTime.now(),
      );

      await AuthService.updateCurrentUserProfile(updatedPerson);

      setState(() {
        _currentPerson = updatedPerson;
        _isEditing = false;
        _hasImageChanged = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildSliverAppBar(),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Informations'),
                            Tab(text: 'Famille'),
                            Tab(text: 'Rôles'),
                            Tab(text: 'Historique'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildInformationTab(),
                    _buildFamilyTab(),
                    _buildRolesTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _currentPerson?.fullName ?? 'Mon Profil',
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildProfileImage(),
              const SizedBox(height: 16),
              if (_currentPerson != null) ...[
                Text(
                  _currentPerson!.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_currentPerson!.roles.isNotEmpty)
                  Text(
                    _currentPerson!.roles.join(', '),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.save : Icons.edit),
          onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _pickProfileImage : null,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
              child: _profileImageUrl != null
                  ? _profileImageUrl!.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(_profileImageUrl!.split(',')[1]),
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: _profileImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildLoadingAvatar(),
                          errorWidget: (context, url, error) => _buildFallbackAvatar(),
                        )
                  : _buildFallbackAvatar(),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    final imageUrl = "https://pixabay.com/get/g8cb3b659d777c09fd00c1d7e509aef546a737b01cee4f68ec7f96b1e4aa41adb2c02b43e07c4925a29e8bd1caab2dcec26e6b295487ed037e490a7581a75f3ea_1280.jpg";

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppTheme.primaryColor.withOpacity(0.3),
        child: const Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.primaryColor.withOpacity(0.3),
        child: const Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: 'Prénom',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Nom',
                icon: Icons.person_outline,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Adresse',
                icon: Icons.location_on_outlined,
                enabled: _isEditing,
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informations personnelles',
            icon: Icons.info_outline,
            children: [
              _buildDateField(),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _gender,
                label: 'Genre',
                icon: Icons.wc,
                items: _genderOptions,
                onChanged: _isEditing ? (value) => setState(() => _gender = value) : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _maritalStatus,
                label: 'Statut marital',
                icon: Icons.favorite_outline,
                items: _maritalStatusOptions,
                onChanged: _isEditing ? (value) => setState(() => _maritalStatus = value) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_family != null) ...[
            _buildInfoCard(
              title: 'Famille : ${_family!.name}',
              icon: Icons.family_restroom,
              children: [
                if (_family!.address != null)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse familiale',
                    value: _family!.address!,
                  ),
                if (_family!.homePhone != null)
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Téléphone familial',
                    value: _family!.homePhone!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Membres de la famille',
              icon: Icons.people,
              children: _familyMembers
                  .map((member) => _buildFamilyMemberItem(member))
                  .toList(),
            ),
          ] else
            _buildInfoCard(
              title: 'Famille',
              icon: Icons.family_restroom,
              children: [
                const Text(
                  'Aucune famille associée',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter création/rejoindre famille
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer ou rejoindre une famille'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Mes rôles',
            icon: Icons.badge,
            children: _currentPerson?.roles.isNotEmpty == true
                ? _currentPerson!.roles.map((roleId) {
                    try {
                      final role = _roles.firstWhere((r) => r.id == roleId);
                      return _buildRoleItem(role);
                    } catch (e) {
                      return _buildRoleItem(RoleModel(
                        id: roleId,
                        name: roleId,
                        description: '',
                        color: '#6F61EF',
                        permissions: [],
                        icon: 'star',
                        isActive: true,
                        createdAt: DateTime.now(),
                      ));
                    }
                  }).toList()
                : [
                    const Text(
                      'Aucun rôle assigné',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Historique des interactions',
            icon: Icons.history,
            children: [
              _buildHistoryItem(
                'Inscription à l\'église',
                _currentPerson?.createdAt ?? DateTime.now(),
                Icons.church,
                AppTheme.primaryColor,
              ),
              _buildHistoryItem(
                'Dernière mise à jour du profil',
                _currentPerson?.updatedAt ?? DateTime.now(),
                Icons.edit,
                AppTheme.secondaryColor,
              ),
              // TODO: Ajouter plus d'historique depuis les logs d'activité
            ],
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey[100],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: onChanged == null,
        fillColor: onChanged == null ? Colors.grey[100] : null,
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _isEditing ? _selectBirthDate : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
          filled: !_isEditing,
          fillColor: _isEditing ? null : Colors.grey[100],
        ),
        child: Text(
          _birthDate != null
              ? _birthDate!.shortDate
              : 'Non renseignée',
          style: TextStyle(
            color: _birthDate != null
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberItem(PersonModel member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(member.displayInitials)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (_family?.headOfFamilyId == member.id)
                  const Text(
                    'Chef de famille',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleItem(RoleModel role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(int.parse(role.color.replaceFirst('#', '0xFF')))
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(int.parse(role.color.replaceFirst('#', '0xFF')))
                .withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconFromString(role.icon),
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (role.description.isNotEmpty)
                    Text(
                      role.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, DateTime date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  date.mediumDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'church':
        return Icons.church;
      case 'groups':
        return Icons.groups;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
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