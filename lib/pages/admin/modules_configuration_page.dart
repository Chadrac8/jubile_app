import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_config_model.dart';
import '../../services/app_config_firebase_service.dart';
import '../../services/pages_firebase_service.dart';
import '../../theme.dart';

class ModulesConfigurationPage extends StatefulWidget {
  const ModulesConfigurationPage({super.key});

  @override
  State<ModulesConfigurationPage> createState() => _ModulesConfigurationPageState();
}

class _ModulesConfigurationPageState extends State<ModulesConfigurationPage> {
  AppConfigModel? _appConfig;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResetting = false;
  List<ModuleConfig> _modules = [];
  List<PageConfig> _customPages = [];

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      // Sync custom pages first to get latest pages
      await AppConfigFirebaseService.syncCustomPages();
      
      final config = await AppConfigFirebaseService.getAppConfig();
      setState(() {
        _appConfig = config;
        _modules = List.from(config.modules);
        _customPages = List.from(config.customPages);
        _isLoading = false;
      });
      
      // Debug: Afficher le nombre de pages trouvées
    } catch (e) {
      print('Erreur lors du chargement de la configuration: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    setState(() {
      _isSaving = true;
    });
    
    try {
      final updatedConfig = AppConfigModel(
        id: _appConfig!.id,
        modules: _modules,
        customPages: _customPages,
        generalSettings: _appConfig!.generalSettings,
        lastUpdated: DateTime.now(),
        lastUpdatedBy: _appConfig!.lastUpdatedBy,
      );
      
      await AppConfigFirebaseService.updateAppConfig(updatedConfig);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sauvegardée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleModuleForMembers(int index) {
    setState(() {
      _modules[index] = _modules[index].copyWith(
        isEnabledForMembers: !_modules[index].isEnabledForMembers,
      );
    });
  }

  void _togglePrimaryInBottomNav(int index) {
    setState(() {
      _modules[index] = _modules[index].copyWith(
        isPrimaryInBottomNav: !_modules[index].isPrimaryInBottomNav,
      );
    });
  }

  void _updateModuleOrder(int index, int newOrder) {
    setState(() {
      _modules[index] = _modules[index].copyWith(order: newOrder);
    });
  }

  void _togglePageForMembers(int index) {
    setState(() {
      _customPages[index] = _customPages[index].copyWith(
        isEnabledForMembers: !_customPages[index].isEnabledForMembers,
      );
    });
  }

  void _togglePagePrimaryInBottomNav(int index) {
    setState(() {
      _customPages[index] = _customPages[index].copyWith(
        isPrimaryInBottomNav: !_customPages[index].isPrimaryInBottomNav,
      );
    });
  }

  void _updatePageOrder(int index, int newOrder) {
    setState(() {
      _customPages[index] = _customPages[index].copyWith(order: newOrder);
    });
  }

  Future<void> _resetConfiguration() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réinitialisation'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser la configuration aux valeurs par défaut ?\n\n'
          'Cette action va :\n'
          '• Remettre les modules avec leur configuration par défaut\n'
          '• Synchroniser les nouvelles pages du Constructeur de Pages\n'
          '• Cette action est irréversible',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isResetting = true;
      });

      try {
        await AppConfigFirebaseService.resetToDefault();
        await _loadConfiguration(); // Recharger la configuration
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration réinitialisée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la réinitialisation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isResetting = false;
          });
        }
      }
    }
  }

  Future<void> _syncCustomPages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🔄 Début synchronisation pages personnalisées...');
      
      // Récupérer toutes les pages disponibles
      final allPages = await PagesFirebaseService.getAllPages();
      
      // Synchroniser
      await AppConfigFirebaseService.syncCustomPages();
      
      // Recharger la configuration
      final config = await AppConfigFirebaseService.getAppConfig();
      setState(() {
        _appConfig = config;
        _modules = List.from(config.modules);
        _customPages = List.from(config.customPages);
      });
      
      print('✅ Pages personnalisées synchronisées: ${_customPages.length}');
      for (var page in _customPages) {
        print('  - Config: "${page.title}" (ID: ${page.id}, Slug: ${page.slug})');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_customPages.length} pages synchronisées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur synchronisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  IconData _getIconForModule(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'groups':
        return Icons.groups;
      case 'event':
        return Icons.event;
      case 'church':
        return Icons.church;
      case 'assignment':
        return Icons.assignment;
      case 'task_alt':
        return Icons.task_alt;
      case 'library_music':
        return Icons.library_music;
      case 'event_available':
        return Icons.event_available;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'notifications':
        return Icons.notifications;
      case 'settings':
        return Icons.settings;
      case 'web':
        return Icons.web;
      case 'dashboard':
        return Icons.dashboard;
      case 'prayer_hands':
        return Icons.favorite;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Modules'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isResetting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _resetConfiguration,
              icon: const Icon(Icons.refresh),
              tooltip: 'Réinitialiser Config',
            ),
          IconButton(
            onPressed: _isLoading ? null : _syncCustomPages,
            icon: const Icon(Icons.sync),
            tooltip: 'Synchroniser Pages',
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save),
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildModulesList(),
                  const SizedBox(height: 24),
                  _buildCustomPagesList(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Cochez "Activé pour les membres" pour rendre un module/page accessible dans la vue membre',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Cochez "Navigation principale" pour afficher le module/page dans la barre de navigation (maximum 4 éléments)',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Les modules et pages non en navigation principale apparaîtront dans le menu "Plus"',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '• Les pages personnalisées proviennent du module Constructeur de Pages',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modules disponibles',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              return _buildModuleItem(module, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleItem(ModuleConfig module, int index) {
    final allPrimaryCount = _modules.where((m) => m.isPrimaryInBottomNav).length +
        _customPages.where((p) => p.isPrimaryInBottomNav).length;
    final canMakePrimary = !module.isPrimaryInBottomNav && allPrimaryCount < 4;
    final canRemoveFromPrimary = module.isPrimaryInBottomNav;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: module.isEnabledForMembers
            ? AppTheme.primaryColor.withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForModule(module.iconName),
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      module.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (module.isPrimaryInBottomNav)
                Chip(
                  label: Text(
                    'Menu principal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: module.isEnabledForMembers,
                      onChanged: (value) => _toggleModuleForMembers(index),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text('Membres'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: module.isPrimaryInBottomNav,
                      onChanged: (canMakePrimary || canRemoveFromPrimary)
                          ? (value) => _togglePrimaryInBottomNav(index)
                          : null,
                      activeColor: AppTheme.primaryColor,
                    ),
                    Text(
                      'Menu principal',
                      style: TextStyle(
                        color: (canMakePrimary || canRemoveFromPrimary)
                            ? AppTheme.textPrimaryColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (module.isPrimaryInBottomNav) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Ordre: '),
                Expanded(
                  child: DropdownButton<int>(
                    value: module.order,
                    onChanged: (newOrder) {
                      if (newOrder != null) {
                        _updateModuleOrder(index, newOrder);
                      }
                    },
                    isExpanded: true,
                    items: List.generate(
                            (_modules.map((m) => m.order).fold<int>(0, (prev, e) => e > prev ? e : prev) + 1),
                            (i) => i)
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text('${i + 1}'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomPagesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.web, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Pages personnalisées',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pages créées avec le Constructeur de Pages',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_customPages.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucune page personnalisée trouvée',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pour voir vos pages ici :',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '1. Allez dans le module Constructeur de Pages\n2. Créez ou modifiez une page\n3. Sauvegardez la page (même en brouillon)\n4. Revenez ici et actualisez',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await _loadConfiguration();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Synchroniser les pages'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._customPages.asMap().entries.map((entry) {
                final index = entry.key;
                final page = entry.value;
                return _buildPageItem(page, index);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem(PageConfig page, int index) {
    final allPrimaryCount = _modules.where((m) => m.isPrimaryInBottomNav).length +
        _customPages.where((p) => p.isPrimaryInBottomNav).length;
    final canMakePrimary = !page.isPrimaryInBottomNav && allPrimaryCount < 4;
    final canRemoveFromPrimary = page.isPrimaryInBottomNav;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: page.isEnabledForMembers
            ? AppTheme.primaryColor.withOpacity(0.05)
            : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForModule(page.iconName),
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      page.description.isNotEmpty ? page.description : 'Page personnalisée',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      'Visibilité: ${_getVisibilityLabel(page.visibility)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (page.isPrimaryInBottomNav)
                Chip(
                  label: Text(
                    'Menu principal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: page.isEnabledForMembers,
                      onChanged: (value) => _togglePageForMembers(index),
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Text('Membres'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: page.isPrimaryInBottomNav,
                      onChanged: (canMakePrimary || canRemoveFromPrimary)
                          ? (value) => _togglePagePrimaryInBottomNav(index)
                          : null,
                      activeColor: AppTheme.primaryColor,
                    ),
                    Text(
                      'Menu principal',
                      style: TextStyle(
                        color: (canMakePrimary || canRemoveFromPrimary)
                            ? AppTheme.textPrimaryColor
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (page.isPrimaryInBottomNav) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Ordre: '),
                Expanded(
                  child: DropdownButton<int>(
                    value: page.order,
                    onChanged: (newOrder) {
                      if (newOrder != null) {
                        _updatePageOrder(index, newOrder);
                      }
                    },
                    isExpanded: true,
                    items: List.generate(
                            (_customPages.map((p) => p.order).fold<int>(0, (prev, e) => e > prev ? e : prev) + 1),
                            (i) => i)
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text('${i + 1}'),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getVisibilityLabel(String visibility) {
    switch (visibility) {
      case 'public':
        return 'Public';
      case 'members':
        return 'Membres connectés';
      case 'groups':
        return 'Groupes spécifiques';
      case 'roles':
        return 'Rôles spécifiques';
      default:
        return visibility;
    }
  }
}