import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_service.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'firebase_storage_diagnostic_page.dart';

class MemberSettingsPage extends StatefulWidget {
  const MemberSettingsPage({super.key});

  @override
  State<MemberSettingsPage> createState() => _MemberSettingsPageState();
}

class _MemberSettingsPageState extends State<MemberSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  
  // Paramètres de notification
  bool _enableNotifications = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _serviceReminders = true;
  bool _groupReminders = true;
  bool _eventNotifications = true;
  bool _formNotifications = true;
  
  // Paramètres de confidentialité
  bool _profileVisible = true;
  bool _showBirthDate = true;
  bool _showPhoneNumber = false;
  
  // Paramètres d'affichage
  bool _darkMode = false;
  String _language = 'Français';
  
  final List<String> _availableLanguages = [
    'Français',
    'English',
    'Español',
    'Português',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _enableNotifications = prefs.getBool('enable_notifications') ?? true;
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _serviceReminders = prefs.getBool('service_reminders') ?? true;
        _groupReminders = prefs.getBool('group_reminders') ?? true;
        _eventNotifications = prefs.getBool('event_notifications') ?? true;
        _formNotifications = prefs.getBool('form_notifications') ?? true;
        
        _profileVisible = prefs.getBool('profile_visible') ?? true;
        _showBirthDate = prefs.getBool('show_birth_date') ?? true;
        _showPhoneNumber = prefs.getBool('show_phone_number') ?? false;
        
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _language = prefs.getString('language') ?? 'Français';
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('enable_notifications', _enableNotifications);
      await prefs.setBool('email_notifications', _emailNotifications);
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setBool('service_reminders', _serviceReminders);
      await prefs.setBool('group_reminders', _groupReminders);
      await prefs.setBool('event_notifications', _eventNotifications);
      await prefs.setBool('form_notifications', _formNotifications);
      
      await prefs.setBool('profile_visible', _profileVisible);
      await prefs.setBool('show_birth_date', _showBirthDate);
      await prefs.setBool('show_phone_number', _showPhoneNumber);
      
      await prefs.setBool('dark_mode', _darkMode);
      await prefs.setString('language', _language);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde : $e'),
            backgroundColor: Theme.of(context).colorScheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(),
    );
    
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _changeEmail() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangeEmailDialog(),
    );
    
    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email modifié avec succès'),
            backgroundColor: Theme.of(context).colorScheme.successColor,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter mes données'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette fonctionnalité permet d\'exporter toutes vos données personnelles :'),
            SizedBox(height: 8),
            Text('• Profil et informations personnelles'),
            Text('• Historique des événements'),
            Text('• Réponses aux formulaires'),
            Text('• Historique des services'),
            SizedBox(height: 16),
            Text(
              'Un fichier ZIP contenant toutes vos données vous sera envoyé par email.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export en cours... Vous recevrez un email sous peu.'),
                  backgroundColor: Theme.of(context).colorScheme.successColor,
                ),
              );
            },
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est définitive et irréversible.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.errorColor,
              ),
            ),
            SizedBox(height: 16),
            Text('Toutes vos données seront supprimées :'),
            SizedBox(height: 8),
            Text('• Profil et informations personnelles'),
            Text('• Historique des événements'),
            Text('• Réponses aux formulaires'),
            Text('• Historique des services'),
            Text('• Tous vos fichiers et images'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorColor,
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion : $e'),
              backgroundColor: Theme.of(context).colorScheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _openStorageDiagnostic() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FirebaseStorageDiagnosticPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.textPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildAccountSection(),
                  const SizedBox(height: 24),
                  _buildNotificationsSection(),
                  const SizedBox(height: 24),
                  _buildPrivacySection(),
                  const SizedBox(height: 24),
                  _buildDisplaySection(),
                  const SizedBox(height: 24),
                  _buildDataSection(),
                  const SizedBox(height: 24),
                  _buildTechnicalSection(),
                  const SizedBox(height: 24),
                  _buildDangerSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? headerColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (headerColor ?? Theme.of(context).colorScheme.primaryColor).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: headerColor ?? Theme.of(context).colorScheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: headerColor ?? Theme.of(context).colorScheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    final user = AuthService.currentUser;
    
    return _buildSectionCard(
      title: 'Compte',
      icon: Icons.account_circle,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Compte connecté'),
          subtitle: Text(user?.email ?? 'Non connecté'),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Changer d\'email'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _changeEmail,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Changer de mot de passe'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _changePassword,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSectionCard(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: const Text('Activer les notifications'),
          subtitle: const Text('Recevoir toutes les notifications'),
          value: _enableNotifications,
          onChanged: (value) {
            setState(() {
              _enableNotifications = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Notifications par email'),
          subtitle: const Text('Recevoir les notifications par email'),
          value: _emailNotifications && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _emailNotifications = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Notifications push'),
          subtitle: const Text('Notifications en temps réel sur l\'appareil'),
          value: _pushNotifications && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _pushNotifications = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        const Text(
          'Types de notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Rappels de services'),
          value: _serviceReminders && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _serviceReminders = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Rappels de groupes'),
          value: _groupReminders && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _groupReminders = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Événements'),
          value: _eventNotifications && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _eventNotifications = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Formulaires'),
          value: _formNotifications && _enableNotifications,
          onChanged: _enableNotifications ? (value) {
            setState(() {
              _formNotifications = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSectionCard(
      title: 'Confidentialité',
      icon: Icons.privacy_tip,
      children: [
        SwitchListTile(
          title: const Text('Profil visible'),
          subtitle: const Text('Votre profil est visible par les autres membres'),
          value: _profileVisible,
          onChanged: (value) {
            setState(() {
              _profileVisible = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Afficher ma date de naissance'),
          value: _showBirthDate && _profileVisible,
          onChanged: _profileVisible ? (value) {
            setState(() {
              _showBirthDate = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Afficher mon numéro de téléphone'),
          value: _showPhoneNumber && _profileVisible,
          onChanged: _profileVisible ? (value) {
            setState(() {
              _showPhoneNumber = value;
            });
          } : null,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return _buildSectionCard(
      title: 'Affichage',
      icon: Icons.display_settings,
      children: [
        SwitchListTile(
          title: const Text('Mode sombre'),
          subtitle: const Text('Interface avec thème sombre'),
          value: _darkMode,
          onChanged: (value) {
            setState(() {
              _darkMode = value;
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Langue'),
          subtitle: Text(_language),
          trailing: DropdownButton<String>(
            value: _language,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _language = value;
                });
              }
            },
            items: _availableLanguages.map((lang) => 
              DropdownMenuItem(
                value: lang,
                child: Text(lang),
              ),
            ).toList(),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSectionCard(
      title: 'Mes données',
      icon: Icons.storage,
      children: [
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Exporter mes données'),
          subtitle: const Text('Télécharger toutes mes informations'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _exportData,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTechnicalSection() {
    return _buildSectionCard(
      title: 'Support technique',
      icon: Icons.build,
      headerColor: Colors.orange,
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_upload, color: Colors.orange),
          title: const Text('Diagnostic Firebase Storage'),
          subtitle: const Text('Tester l\'upload d\'images et la connectivité'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openStorageDiagnostic,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return _buildSectionCard(
      title: 'Zone de danger',
      icon: Icons.warning,
      headerColor: Theme.of(context).colorScheme.errorColor,
      children: [
        ListTile(
          leading: const Icon(Icons.logout, color: Theme.of(context).colorScheme.warningColor),
          title: const Text('Se déconnecter'),
          subtitle: const Text('Déconnecter ce compte'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _signOut,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.errorColor),
          title: const Text(
            'Supprimer mon compte',
            style: TextStyle(color: Theme.of(context).colorScheme.errorColor),
          ),
          subtitle: const Text('Suppression définitive et irréversible'),
          trailing: const Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.errorColor),
          onTap: _deleteAccount,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer de mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe actuel';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un nouveau mot de passe';
                }
                if (value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Implémenter le changement de mot de passe
              Navigator.pop(context, true);
            }
          },
          child: const Text('Modifier'),
        ),
      ],
    );
  }
}

class _ChangeEmailDialog extends StatefulWidget {
  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer d\'email'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Nouvel email',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un email';
                }
                if (!value.contains('@')) {
                  return 'Veuillez saisir un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // TODO: Implémenter le changement d'email
              Navigator.pop(context, true);
            }
          },
          child: const Text('Modifier'),
        ),
      ],
    );
  }
}