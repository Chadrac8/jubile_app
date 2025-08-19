import 'package:flutter/material.dart';
import '../../compatibility/app_theme_bridge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/songs/models/song_model.dart';

/// Page de debug dédiée pour comprendre pourquoi les chants ne s'affichent pas
class SongsDebugPage extends StatefulWidget {
  const SongsDebugPage({super.key});

  @override
  State<SongsDebugPage> createState() => _SongsDebugPageState();
}

class _SongsDebugPageState extends State<SongsDebugPage> {
  Map<String, dynamic> _debugInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _runDebugAnalysis();
  }

  Future<void> _runDebugAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 DÉBUT DE L\'ANALYSE DEBUG DES CHANTS');
      
      // 1. Test de connexion Firestore basique
      final firestore = FirebaseFirestore.instance;
      
      // 2. Récupération directe de tous les documents
      final allDocsSnapshot = await firestore.collection('songs').get();
      print('📊 Total de documents dans Firestore: ${allDocsSnapshot.docs.length}');
      
      // 3. Analyse des statuts
      final statusCounts = <String, int>{};
      final visibilityCounts = <String, int>{};
      final conversionErrors = <String>[];
      final validSongs = <SongModel>[];
      
      for (final doc in allDocsSnapshot.docs) {
        try {
          final data = doc.data();
          final status = data['status']?.toString() ?? 'undefined';
          final visibility = data['visibility']?.toString() ?? 'undefined';
          
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          visibilityCounts[visibility] = (visibilityCounts[visibility] ?? 0) + 1;
          
          // Test de conversion en SongModel
          final song = SongModel.fromFirestore(doc);
          validSongs.add(song);
          
        } catch (e) {
          conversionErrors.add('Doc ${doc.id}: $e');
          print('❌ Erreur conversion document ${doc.id}: $e');
        }
      }
      
      // 4. Test de la méthode getAllSongsNoFilter()
      final streamSongs = <SongModel>[];
      await for (final songs in FirebaseFirestore.instance.collection('songs').snapshots().take(1)) {
        for (final doc in songs.docs) {
          try {
            streamSongs.add(SongModel.fromFirestore(doc));
          } catch (e) {
            print('❌ Erreur stream conversion ${doc.id}: $e');
          }
        }
        break;
      }
      
      setState(() {
        _debugInfo = {
          'totalDocuments': allDocsSnapshot.docs.length,
          'validSongsConverted': validSongs.length,
          'streamSongsConverted': streamSongs.length,
          'conversionErrors': conversionErrors.length,
          'statusCounts': statusCounts,
          'visibilityCounts': visibilityCounts,
          'sampleTitles': validSongs.take(10).map((s) => s.title).toList(),
          'errors': conversionErrors.take(10).toList(),
        };
        _isLoading = false;
      });
      
      print('✅ ANALYSE DEBUG TERMINÉE');
      print('📊 Résultat: ${validSongs.length} chants valides sur ${allDocsSnapshot.docs.length} documents');
      
    } catch (e) {
      print('❌ ERREUR DURANT L\'ANALYSE DEBUG: $e');
      setState(() {
        _debugInfo = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Chants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDebugAnalysis),
        ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard('📊 Statistiques Globales', {
                    'Documents Firestore': _debugInfo['totalDocuments'],
                    'Chants convertis (direct)': _debugInfo['validSongsConverted'],
                    'Chants convertis (stream)': _debugInfo['streamSongsConverted'],
                    'Erreurs de conversion': _debugInfo['conversionErrors'],
                  }),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoCard('🏷️ Répartition par Status', _debugInfo['statusCounts'] ?? {}),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoCard('👁️ Répartition par Visibilité', _debugInfo['visibilityCounts'] ?? {}),
                  
                  const SizedBox(height: 16),
                  
                  _buildSampleTitles(),
                  
                  if ((_debugInfo['errors'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildErrorsList(),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Bouton pour tester la vue membre
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/member/songs');
                      },
                      icon: const Icon(Icons.music_note),
                      label: const Text('Tester Vue Membre'))),
                ])));
  }

  Widget _buildInfoCard(String title, Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                ]))),
          ])));
  }

  Widget _buildSampleTitles() {
    final titles = _debugInfo['sampleTitles'] as List? ?? [];
    if (titles.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎵 Exemples de Titres (10 premiers)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...titles.map((title) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $title'))),
          ])));
  }

  Widget _buildErrorsList() {
    final errors = _debugInfo['errors'] as List? ?? [];
    if (errors.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: Theme.of(context).colorScheme.errorColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '❌ Erreurs de Conversion (10 premières)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.errorColor)),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $error',
                style: TextStyle(color: Theme.of(context).colorScheme.errorColor, fontSize: 12)))),
          ])));
  }
}
