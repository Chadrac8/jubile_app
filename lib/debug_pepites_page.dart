import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/auth_service.dart';

/// Page de débogage pour tester les pépites d'or
class DebugPepitesPage extends StatefulWidget {
  const DebugPepitesPage({Key? key}) : super(key: key);

  @override
  State<DebugPepitesPage> createState() => _DebugPepitesPageState();
}

class _DebugPepitesPageState extends State<DebugPepitesPage> {
  String _status = 'Prêt';
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Pépites d\'Or'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: AppTheme.surfaceColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Status: $_status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold)))),
            const SizedBox(height: 16),
            
            // Boutons de test
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _testFirebaseConnection,
                  child: const Text('Test Firebase')),
                ElevatedButton(
                  onPressed: _testCreatePepite,
                  child: const Text('Créer Test Pépite')),
                ElevatedButton(
                  onPressed: _testStreamPepites,
                  child: const Text('Test Stream')),
                ElevatedButton(
                  onPressed: _clearLogs,
                  child: const Text('Effacer logs')),
              ]),
            const SizedBox(height: 16),
            
            // Logs
            const Text(
              'Logs:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.textTertiaryColor),
                  borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12)));
                  }))),
          ])));
  }

  Future<void> _testFirebaseConnection() async {
    setState(() => _status = 'Test connexion Firebase...');
    _addLog('🔄 Test de connexion Firebase');
    
    try {
      final firestore = FirebaseFirestore.instance;
      final testDoc = await firestore.collection('test').doc('connection').get();
      _addLog('✅ Connexion Firebase OK');
      _addLog('📄 Document test existe: ${testDoc.exists}');
      setState(() => _status = 'Firebase connecté');
    } catch (e) {
      _addLog('❌ Erreur Firebase: $e');
      setState(() => _status = 'Erreur Firebase');
    }
  }

  Future<void> _testCreatePepite() async {
    setState(() => _status = 'Création pépite test...');
    _addLog('🔄 Création d\'une pépite de test');
    
    try {
      final currentUser = await AuthService.getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final firestore = FirebaseFirestore.instance;
      
      final pepiteData = {
        'theme': 'Test',
        'description': 'Pépite de test créée le ${DateTime.now()}',
        'auteur': currentUser.id,
        'nomAuteur': '${currentUser.firstName} ${currentUser.lastName}',
        'citations': [
          {
            'id': 'ct1',
            'texte': 'Ceci est une citation de test.',
            'auteur': 'Test Auteur',
            'reference': 'Test 1:1',
            'ordre': 1,
          }
        ],
        'tags': ['test', 'debug'],
        'estPubliee': true,
        'dateCreation': Timestamp.now(),
        'datePublication': Timestamp.now(),
        'estFavorite': false,
        'nbVues': 0,
        'nbPartages': 0,
        'imageUrl': null,
      };

      final docRef = await firestore.collection('pepites_or').add(pepiteData);
      _addLog('✅ Pépite créée avec ID: ${docRef.id}');
      setState(() => _status = 'Pépite créée');
    } catch (e) {
      _addLog('❌ Erreur création pépite: $e');
      setState(() => _status = 'Erreur création');
    }
  }

  Future<void> _testStreamPepites() async {
    setState(() => _status = 'Test stream pépites...');
    _addLog('🔄 Test du stream des pépites');
    
    try {
      final firestore = FirebaseFirestore.instance;
      final stream = firestore
          .collection('pepites_or')
          .where('estPubliee', isEqualTo: true)
          .snapshots();
      
      stream.listen(
        (snapshot) {
          _addLog('📚 Stream reçu: ${snapshot.docs.length} documents');
          for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
            final data = snapshot.docs[i].data();
            _addLog('  - ${data['theme']}: ${data['description']}');
          }
          setState(() => _status = '${snapshot.docs.length} pépites reçues');
        },
        onError: (error) {
          _addLog('❌ Erreur stream: $error');
          setState(() => _status = 'Erreur stream');
        });
    } catch (e) {
      _addLog('❌ Erreur initialisation stream: $e');
      setState(() => _status = 'Erreur stream init');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
      _status = 'Logs effacés';
    });
  }
}
