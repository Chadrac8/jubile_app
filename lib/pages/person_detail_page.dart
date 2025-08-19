import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/person_model.dart';
import '../models/custom_field_model.dart';
import '../services/firebase_service.dart';
import '../services/custom_fields_firebase_service.dart';
import '../widgets/family_widget.dart';
import '../widgets/workflow_tracker.dart';
import '../widgets/custom_fields_widget.dart';
import '../widgets/my_assigned_workflows_widget.dart';
import 'person_form_page.dart';
import '../../compatibility/app_theme_bridge.dart';


class PersonDetailPage extends StatefulWidget {
  final PersonModel person;

  const PersonDetailPage({
    super.key,
    required this.person,
  });

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  PersonModel? _currentPerson;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPerson = widget.person;
    _tabController = TabController(length: 5, vsync: this);
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
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

  Future<void> _refreshPersonData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedPerson = await FirebaseService.getPerson(widget.person.id);
      if (updatedPerson != null) {
        setState(() {
          _currentPerson = updatedPerson;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rechargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editPerson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonFormPage(person: _currentPerson),
      ),
    );
    
    if (result == true) {
      await _refreshPersonData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Informations mises à jour avec succès'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _toggleActiveStatus() async {
    try {
      final updatedPerson = _currentPerson!.copyWith(
        isActive: !_currentPerson!.isActive,
      );
      
      await FirebaseService.updatePerson(updatedPerson);
      setState(() {
        _currentPerson = updatedPerson;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentPerson!.isActive
                  ? 'Membre réactivé'
                  : 'Membre désactivé',
            ),
            backgroundColor: _currentPerson!.isActive
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: \$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    final imageUrl = "https://images.unsplash.com/photo-1669575874559-e8b9c70d1ca1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDgzNTY2MzR8&ixlib=rb-4.1.0&q=80&w=1080";

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: _currentPerson?.profileImageUrl != null
            ? (_currentPerson!.profileImageUrl!.startsWith('data:image')
                ? Image.memory(
                    Uri.parse(_currentPerson!.profileImageUrl!).data!.contentAsBytes(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(),
                  )
                : CachedNetworkImage(
                    imageUrl: _currentPerson!.profileImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildLoadingAvatar(),
                    errorWidget: (context, url, error) => _buildFallbackAvatar(),
                  ))
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingAvatar(),
                errorWidget: (context, url, error) => _buildFallbackAvatar(),
              ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          _currentPerson?.displayInitials ?? '??',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPerson == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with profile image and basic info
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      
                      // Profile Image
                      Hero(
                        tag: 'profile_\${_currentPerson!.id}',
                        child: _buildProfileImage(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name and Status
                      Text(
                        _currentPerson!.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentPerson!.isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _currentPerson!.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentPerson!.isActive ? Icons.check_circle : Icons.cancel,
                              color: _currentPerson!.isActive ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentPerson!.isActive ? 'Actif' : 'Inactif',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _currentPerson!.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(_currentPerson!.isActive ? Icons.block : Icons.check_circle),
                        const SizedBox(width: 8),
                        Text(_currentPerson!.isActive ? 'Désactiver' : 'Réactiver'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'workflow',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add_check),
                        SizedBox(width: 8),
                        Text('Démarrer un suivi'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editPerson();
                      break;
                    case 'toggle_status':
                      _toggleActiveStatus();
                      break;
                    case 'workflow':
                      _showWorkflowSelectionDialog();
                      break;
                  }
                },
              ),
            ],
          ),
          
          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Informations', icon: Icon(Icons.person)),
                  Tab(text: 'Famille', icon: Icon(Icons.family_restroom)),
                  Tab(text: 'Suivis', icon: Icon(Icons.playlist_add_check)),
                  Tab(text: 'Mes suivis', icon: Icon(Icons.assignment_ind)),
                  Tab(text: 'Historique', icon: Icon(Icons.history)),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.outline,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          
          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(),
                _buildFamilyTab(),
                _buildWorkflowTab(),
                _buildMyAssignedWorkflowsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton(
              onPressed: _editPerson,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.edit),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInformationTab() {
    return RefreshIndicator(
      onRefresh: _refreshPersonData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Information Card
            _buildInfoCard(
              title: 'Informations de Contact',
              icon: Icons.contact_phone,
              children: [
                if (_currentPerson!.email.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: _currentPerson!.email,
                    onTap: () => _launchEmail(_currentPerson!.email),
                  ),
                if (_currentPerson!.phone != null)
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: _currentPerson!.phone!,
                    onTap: () => _launchPhone(_currentPerson!.phone!),
                  ),
                if (_currentPerson!.address != null)
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Adresse',
                    value: _currentPerson!.address!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Personal Information Card
            _buildInfoCard(
              title: 'Informations Personnelles',
              icon: Icons.person,
              children: [
                if (_currentPerson!.birthDate != null)
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'Date de naissance',
                    value: _currentPerson!.formattedBirthDate!,
                    subtitle: _currentPerson!.age != null ? '${_currentPerson!.age} ans' : null,
                  ),
                if (_currentPerson!.gender != null)
                  _buildInfoRow(
                    icon: _currentPerson!.gender == 'Male' ? Icons.man : Icons.woman,
                    label: 'Genre',
                    value: _currentPerson!.gender!,
                  ),
                if (_currentPerson!.maritalStatus != null)
                  _buildInfoRow(
                    icon: Icons.favorite,
                    label: 'Statut marital',
                    value: _currentPerson!.maritalStatus!,
                  ),
                if (_currentPerson!.children.isNotEmpty)
                  _buildInfoRow(
                    icon: Icons.child_friendly,
                    label: 'Enfants',
                    value: _currentPerson!.children.join(', '),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Roles and Tags Card
            if (_currentPerson!.roles.isNotEmpty || _currentPerson!.tags.isNotEmpty)
              _buildInfoCard(
                title: 'Rôles et Tags',
                icon: Icons.local_offer,
                children: [
                  if (_currentPerson!.roles.isNotEmpty) ...[
                    _buildTagSection('Rôles', _currentPerson!.roles, Colors.blue),
                    if (_currentPerson!.tags.isNotEmpty) const SizedBox(height: 12),
                  ],
                  if (_currentPerson!.tags.isNotEmpty)
                    _buildTagSection('Tags', _currentPerson!.tags, Colors.green),
                ],
              ),
            
            // Private Notes Card (Admin only)
            if (_currentPerson!.privateNotes != null && _currentPerson!.privateNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Notes Privées',
                icon: Icons.note,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _currentPerson!.privateNotes!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Custom Fields Card
            if (_currentPerson!.customFields.isNotEmpty) ...[
              const SizedBox(height: 16),
              
              // Custom Fields with proper display
              FutureBuilder<List<CustomFieldModel>>(
                future: CustomFieldsFirebaseService().getCustomFields(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return CustomFieldsDisplayWidget(
                      values: _currentPerson!.customFields,
                      fields: snapshot.data!,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.open_in_new,
                    color: Theme.of(context).colorScheme.outline,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFamilyTab() {
    return FamilyWidget(person: _currentPerson!);
  }

  Widget _buildWorkflowTab() {
    return WorkflowTracker(person: _currentPerson!);
  }

  Widget _buildMyAssignedWorkflowsTab() {
    if (_currentPerson?.id == null) {
      return const Center(
        child: Text('Impossible de charger les suivis assignés'),
      );
    }
    
    return MyAssignedWorkflowsWidget(
      personId: _currentPerson!.id,
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des modifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildHistoryItem(
                  'Création du profil',
                  _currentPerson!.createdAt,
                  Icons.person_add,
                  Colors.green,
                ),
                if (_currentPerson!.createdAt != _currentPerson!.updatedAt)
                  _buildHistoryItem(
                    'Dernière modification',
                    _currentPerson!.updatedAt,
                    Icons.edit,
                    Colors.blue,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, DateTime date, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\${date.day}/\${date.month}/\${date.year} à \${date.hour}:\${date.minute.toString().padLeft(2, \'0\')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWorkflowSelectionDialog() async {
    try {
      final workflows = await FirebaseService.getWorkflowsStream().first;
      
      if (!mounted) return;

      if (workflows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aucun workflow disponible'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final selectedWorkflow = await showDialog<WorkflowModel>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  Icons.playlist_add_check,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Démarrer un suivi'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sélectionnez un workflow pour ${_currentPerson!.fullName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: workflows.length,
                      itemBuilder: (context, index) {
                        final workflow = workflows[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(int.parse(workflow.color.replaceAll('#', '0xFF'))).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconFromString(workflow.icon),
                                color: Color(int.parse(workflow.color.replaceAll('#', '0xFF'))),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              workflow.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(workflow.description),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      workflow.category,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.list,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${workflow.steps.length} étape(s)',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pop(context, workflow),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );

      if (selectedWorkflow != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          await FirebaseService.startWorkflowForPerson(_currentPerson!.id, selectedWorkflow.id);
          
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Workflow "${selectedWorkflow.name}" démarré avec succès'),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 4),
              ),
            );

            // Switch to the workflow tab to show the new workflow
            _tabController.animateTo(2); // Index 2 is the Suivis tab
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors du démarrage du workflow: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'waving_hand':
        return Icons.waving_hand;
      case 'favorite':
        return Icons.favorite;
      case 'school':
        return Icons.school;
      case 'healing':
        return Icons.healing;
      case 'water_drop':
        return Icons.water_drop;
      case 'track_changes':
      default:
        return Icons.track_changes;
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
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}