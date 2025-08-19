import 'package:flutter/material.dart';
import '../../../theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/thematic_passage_service.dart';

/// Widget de débogage pour les passages thématiques
class ThematicPassagesDebugWidget extends StatefulWidget {
  const ThematicPassagesDebugWidget({Key? key}) : super(key: key);

  @override
  State<ThematicPassagesDebugWidget> createState() => _ThematicPassagesDebugWidgetState();
}

class _ThematicPassagesDebugWidgetState extends State<ThematicPassagesDebugWidget> {
  String _debugInfo = 'Initialisation du débogage...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Démarrage des diagnostics...\n';
    });

    try {
      // Test 1: Firebase Core
      _appendDebug('1. Test Firebase Core...');
      final app = Firebase.app();
      _appendDebug('✅ Firebase Core OK: ${app.name}');

      // Test 2: Firestore connexion
      _appendDebug('\n2. Test Firestore connexion...');
      final firestore = FirebaseFirestore.instance;
      await firestore.doc('test/connection').get();
      _appendDebug('✅ Firestore connexion OK');

      // Test 3: Vérification des collections
      _appendDebug('\n3. Vérification des collections...');
      final themesCollection = await firestore.collection('biblical_themes').limit(1).get();
      _appendDebug('📊 Collection biblical_themes: ${themesCollection.docs.length} documents');

      final passagesCollection = await firestore.collection('thematic_passages').limit(1).get();
      _appendDebug('📊 Collection thematic_passages: ${passagesCollection.docs.length} documents');

      // Test 4: Service ThematicPassageService
      _appendDebug('\n4. Test service connexion...');
      final isConnected = await ThematicPassageService.checkFirebaseConnection();
      _appendDebug(isConnected ? '✅ Service connexion OK' : '❌ Service connexion KO');

      // Test 5: Initialisation thèmes par défaut
      _appendDebug('\n5. Test initialisation des thèmes...');
      await ThematicPassageService.initializeDefaultThemes();
      _appendDebug('✅ Initialisation des thèmes terminée');

      // Test 6: Recompte après initialisation
      _appendDebug('\n6. Recompte après initialisation...');
      final themesAfter = await firestore.collection('biblical_themes').where('isPublic', isEqualTo: true).get();
      _appendDebug('📊 Thèmes publics trouvés: ${themesAfter.docs.length}');

      final passagesAfter = await firestore.collection('thematic_passages').get();
      _appendDebug('📊 Passages totaux: ${passagesAfter.docs.length}');

      _appendDebug('\n✅ Tous les diagnostics terminés avec succès!');

    } catch (e, stackTrace) {
      _appendDebug('\n❌ Erreur lors des diagnostics: $e');
      _appendDebug('Stack trace: $stackTrace');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _appendDebug(String message) {
    setState(() {
      _debugInfo += message + '\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Passages Thématiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runDiagnostics),
        ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
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
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12))))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      await _testStreamSubscription();
                    },
                    child: const Text('Test Stream'))),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      await _clearAllData();
                    },
                    child: const Text('Réinitialiser'))),
              ]),
          ])));
  }

  Future<void> _testStreamSubscription() async {
    _appendDebug('\n🔄 Test du stream getPublicThemes...');
    
    try {
      final stream = ThematicPassageService.getPublicThemes();
      final subscription = stream.listen(
        (themes) {
          _appendDebug('📡 Stream émis: ${themes.length} thèmes reçus');
          for (final theme in themes) {
            _appendDebug('  - ${theme.name}: ${theme.passages.length} passages');
          }
        },
        onError: (error) {
          _appendDebug('❌ Erreur dans le stream: $error');
        });

      // Attendre 5 secondes puis annuler
      await Future.delayed(const Duration(seconds: 5));
      subscription.cancel();
      _appendDebug('✅ Test du stream terminé');
    } catch (e) {
      _appendDebug('❌ Erreur lors du test du stream: $e');
    }
  }

  Future<void> _clearAllData() async {
    _appendDebug('\n🗑️ Nettoyage des données...');
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Supprimer tous les thèmes
      final themesSnapshot = await firestore.collection('biblical_themes').get();
      for (final doc in themesSnapshot.docs) {
        await doc.reference.delete();
      }
      _appendDebug('✅ ${themesSnapshot.docs.length} thèmes supprimés');
      
      // Supprimer tous les passages
      final passagesSnapshot = await firestore.collection('thematic_passages').get();
      for (final doc in passagesSnapshot.docs) {
        await doc.reference.delete();
      }
      _appendDebug('✅ ${passagesSnapshot.docs.length} passages supprimés');
      
      _appendDebug('✅ Nettoyage terminé');
    } catch (e) {
      _appendDebug('❌ Erreur lors du nettoyage: $e');
    }
  }
}
