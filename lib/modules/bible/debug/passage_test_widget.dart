import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/thematic_passage_service.dart';
import '../widgets/add_passage_dialog.dart';
import '../widgets/theme_creation_dialog.dart';

/// Widget de diagnostic pour tester l'ajout de passages bibliques
class PassageTestWidget extends StatefulWidget {
  const PassageTestWidget({Key? key}) : super(key: key);

  @override
  State<PassageTestWidget> createState() => _PassageTestWidgetState();
}

class _PassageTestWidgetState extends State<PassageTestWidget> {
  String? _testThemeId;
  String _statusText = 'Prêt pour les tests...';
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _statusText = 'Utilisateur connecté: ${_currentUser!.uid}';
      } else {
        _statusText = 'Aucun utilisateur connecté';
      }
    });
  }

  Future<void> _createTestTheme() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Création du thème de test...';
    });

    try {
      _testThemeId = await ThematicPassageService.createTheme(
        name: 'Test UI ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Thème de test pour l\'interface utilisateur',
        color: Colors.blue,
        icon: Icons.star,
        isPublic: false);

      setState(() {
        _statusText = 'Thème de test créé: $_testThemeId';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Erreur création thème: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddPassageDialog() {
    if (_testThemeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Créez d\'abord un thème de test'),
          backgroundColor: Theme.of(context).colorScheme.warningColor));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddPassageDialog(
        themeId: _testThemeId!,
        themeName: 'Thème de test')).then((result) {
      if (result == true) {
        setState(() {
          _statusText = 'Passage ajouté avec succès!';
        });
      }
    });
  }

  void _showCreateThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => const ThemeCreationDialog()).then((result) {
      if (result == true) {
        setState(() {
          _statusText = 'Nouveau thème créé depuis l\'interface!';
        });
      }
    });
  }

  Future<void> _testDirectAdd() async {
    if (_testThemeId == null) {
      await _createTestTheme();
      if (_testThemeId == null) return;
    }

    setState(() {
      _isLoading = true;
      _statusText = 'Test d\'ajout direct...';
    });

    try {
      await ThematicPassageService.addPassageToTheme(
        themeId: _testThemeId!,
        reference: 'Jean 3:16',
        book: 'Jean',
        chapter: 3,
        startVerse: 16,
        description: 'Test d\'ajout direct depuis l\'interface');

      setState(() {
        _statusText = 'Ajout direct réussi!';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Erreur ajout direct: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanup() async {
    if (_testThemeId == null) return;

    setState(() {
      _isLoading = true;
      _statusText = 'Suppression du thème de test...';
    });

    try {
      await ThematicPassageService.deleteTheme(_testThemeId!);
      setState(() {
        _testThemeId = null;
        _statusText = 'Thème de test supprimé';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Erreur suppression: $e';
      });
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
        title: const Text('Test Passages Bibliques'),
        backgroundColor: Colors.blue,
        foregroundColor: Theme.of(context).colorScheme.surfaceColor),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // État de l'authentification
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentUser != null ? Theme.of(context).colorScheme.successColor : Theme.of(context).colorScheme.warningColor,
                border: Border.all(
                  color: _currentUser != null ? Theme.of(context).colorScheme.successColor : Theme.of(context).colorScheme.warningColor),
                borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentUser != null ? Icons.check_circle : Icons.warning,
                        color: _currentUser != null ? Theme.of(context).colorScheme.successColor : Theme.of(context).colorScheme.warningColor),
                      const SizedBox(width: 8),
                      Text(
                        'État de l\'authentification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentUser != null ? Theme.of(context).colorScheme.successColor : Theme.of(context).colorScheme.warningColor)),
                    ]),
                  const SizedBox(height: 8),
                  Text(_currentUser != null 
                    ? 'Connecté: ${_currentUser!.uid}' 
                    : 'Non connecté - L\'authentification sera automatique'),
                ])),

            const SizedBox(height: 20),

            // Tests disponibles
            Text(
              'Tests disponibles:',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            // Boutons de test
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestTheme,
                  icon: const Icon(Icons.add),
                  label: const Text('1. Créer thème test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Theme.of(context).colorScheme.surfaceColor)),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showAddPassageDialog,
                  icon: const Icon(Icons.library_books),
                  label: const Text('2. Dialog ajout passage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.successColor,
                    foregroundColor: Theme.of(context).colorScheme.surfaceColor)),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testDirectAdd,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('3. Test ajout direct'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Theme.of(context).colorScheme.surfaceColor)),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCreateThemeDialog,
                  icon: const Icon(Icons.create),
                  label: const Text('4. Dialog création thème'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.warningColor,
                    foregroundColor: Theme.of(context).colorScheme.surfaceColor)),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _cleanup,
                  icon: const Icon(Icons.delete),
                  label: const Text('5. Nettoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorColor,
                    foregroundColor: Theme.of(context).colorScheme.surfaceColor)),
              ]),

            const SizedBox(height: 20),

            if (_isLoading)
              const LinearProgressIndicator(),

            const SizedBox(height: 20),

            // Zone de statut
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.textTertiaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.textTertiaryColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'État des tests:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14)))),
                  ]))),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions de test:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800])),
                  const SizedBox(height: 8),
                  const Text('1. Créez un thème de test'),
                  const Text('2. Testez l\'ajout via le dialog (comme un utilisateur)'),
                  const Text('3. Testez l\'ajout direct (pour vérifier le service)'),
                  const Text('4. Nettoyez après les tests'),
                ])),
          ])));
  }
}
