import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/thematic_passage_service.dart';

/// Widget de test pour l'authentification et les opérations de création/modification
class AuthTestWidget extends StatefulWidget {
  const AuthTestWidget({Key? key}) : super(key: key);

  @override
  State<AuthTestWidget> createState() => _AuthTestWidgetState();
}

class _AuthTestWidgetState extends State<AuthTestWidget> {
  String _statusText = 'Initialisation...';
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Vérification de l\'authentification...\n';
    });

    try {
      // Vérifier l'état actuel de l'authentification
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser == null) {
        _appendStatus('❌ Utilisateur non connecté');
        _appendStatus('👤 Tentative de connexion anonyme...');
        
        // Essayer une connexion anonyme
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        _currentUser = userCredential.user;
        
        if (_currentUser != null) {
          _appendStatus('✅ Connexion anonyme réussie');
          _appendStatus('📱 UID: ${_currentUser!.uid}');
        }
      } else {
        _appendStatus('✅ Utilisateur déjà connecté');
        _appendStatus('📱 UID: ${_currentUser!.uid}');
        _appendStatus('👤 Nom: ${_currentUser!.displayName ?? "Anonyme"}');
        _appendStatus('📧 Email: ${_currentUser!.email ?? "Aucun"}');
      }

      // Tester la création d'un thème
      await _testThemeCreation();
      
    } catch (e) {
      _appendStatus('❌ Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testThemeCreation() async {
    _appendStatus('\n🧪 Test de création de thème...');
    
    try {
      final themeId = await ThematicPassageService.createTheme(
        name: 'Test Thème ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Thème de test pour vérifier les permissions',
        color: Colors.blue,
        icon: Icons.star,
        isPublic: false);
      
      _appendStatus('✅ Thème créé avec succès!');
      _appendStatus('🆔 ID du thème: $themeId');
      
      // Tester la mise à jour
      await _testThemeUpdate(themeId);
      
    } catch (e) {
      _appendStatus('❌ Erreur lors de la création: $e');
    }
  }

  Future<void> _testThemeUpdate(String themeId) async {
    _appendStatus('\n🔄 Test de mise à jour du thème...');
    
    try {
      await ThematicPassageService.updateTheme(
        themeId: themeId,
        name: 'Test Thème Modifié',
        description: 'Description modifiée',
        color: AppTheme.successColor,
        icon: Icons.favorite,
        isPublic: false);
      
      _appendStatus('✅ Thème mis à jour avec succès!');
      
      // Nettoyer: supprimer le thème de test
      await _cleanupTestTheme(themeId);
      
    } catch (e) {
      _appendStatus('❌ Erreur lors de la mise à jour: $e');
    }
  }

  Future<void> _cleanupTestTheme(String themeId) async {
    _appendStatus('\n🧹 Nettoyage du thème de test...');
    
    try {
      await ThematicPassageService.deleteTheme(themeId);
      _appendStatus('✅ Thème de test supprimé');
    } catch (e) {
      _appendStatus('⚠️ Erreur lors du nettoyage: $e');
    }
  }

  void _appendStatus(String message) {
    setState(() {
      _statusText += message + '\n';
    });
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _appendStatus('\n👤 Connexion anonyme...');
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _currentUser = userCredential.user;
      _appendStatus('✅ Connexion réussie!');
      _appendStatus('📱 UID: ${_currentUser!.uid}');
    } catch (e) {
      _appendStatus('❌ Erreur de connexion: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      _currentUser = null;
      _appendStatus('\n🔓 Déconnexion réussie');
    } catch (e) {
      _appendStatus('❌ Erreur de déconnexion: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Authentification'),
        backgroundColor: Colors.blue,
        foregroundColor: AppTheme.surfaceColor),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur d'état
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentUser != null ? AppTheme.successColor : AppTheme.errorColor,
                border: Border.all(
                  color: _currentUser != null ? AppTheme.successColor : AppTheme.errorColor),
                borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(
                    _currentUser != null ? Icons.check_circle : Icons.error,
                    color: _currentUser != null ? AppTheme.successColor : AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Text(
                    _currentUser != null ? 'Connecté' : 'Non connecté',
                    style: TextStyle(
                      color: _currentUser != null ? AppTheme.successColor : AppTheme.errorColor,
                      fontWeight: FontWeight.bold)),
                ])),
            
            const SizedBox(height: 16),
            
            // Boutons d'actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInAnonymously,
                    child: const Text('Connexion Anonyme'))),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: AppTheme.surfaceColor),
                    child: const Text('Déconnexion'))),
              ]),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAuthStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: AppTheme.surfaceColor,
                minimumSize: const Size(double.infinity, 48)),
              child: const Text('Retester les opérations')),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const LinearProgressIndicator(),
            
            const SizedBox(height: 16),
            
            // Zone de logs
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.textTertiaryColor)),
                child: SingleChildScrollView(
                  child: Text(
                    _statusText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12))))),
          ])));
  }
}
