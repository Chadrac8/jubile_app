import 'package:cloud_firestore/cloud_firestore.dart';
import '../modules/songs/models/song_model.dart';

/// Script de debug pour analyser les chants dans Firebase
class SongsDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _songsCollection = 'songs';

  /// Vérifie tous les chants dans la base de données
  static Future<void> debugAllSongs() async {
    try {
      print('🔍 === DEBUG ANALYSE DES CHANTS ===');
      
      // Récupérer tous les chants sans filtre
      final snapshot = await _firestore.collection(_songsCollection).get();
      
      if (snapshot.docs.isEmpty) {
        print('❌ Aucun chant trouvé dans la collection "$_songsCollection"');
        return;
      }

      print('📊 Total chants trouvés: ${snapshot.docs.length}');
      print('');

      // Analyser chaque chant
      Map<String, int> statusCounts = {};
      Map<String, int> visibilityCounts = {};
      List<Map<String, dynamic>> songsSummary = [];

      for (var doc in snapshot.docs) {
        try {
          final song = SongModel.fromFirestore(doc);
          
          // Compter les statuts
          statusCounts[song.status] = (statusCounts[song.status] ?? 0) + 1;
          
          // Compter les visibilités
          visibilityCounts[song.visibility] = (visibilityCounts[song.visibility] ?? 0) + 1;
          
          // Résumé du chant
          songsSummary.add({
            'id': song.id,
            'title': song.title,
            'status': song.status,
            'visibility': song.visibility,
            'authors': song.authors,
            'createdAt': song.createdAt.toString(),
          });
          
        } catch (e) {
          print('❌ Erreur parsing chant ${doc.id}: $e');
        }
      }

      // Afficher les statistiques
      print('📈 STATISTIQUES PAR STATUT:');
      statusCounts.forEach((status, count) {
        print('  • $status: $count chants');
      });
      print('');

      print('👁️ STATISTIQUES PAR VISIBILITÉ:');
      visibilityCounts.forEach((visibility, count) {
        print('  • $visibility: $count chants');
      });
      print('');

      // Afficher les premiers chants
      print('🎵 APERÇU DES CHANTS (premiers 10):');
      for (int i = 0; i < songsSummary.length && i < 10; i++) {
        final song = songsSummary[i];
        print('  ${i + 1}. "${song['title']}" - ${song['status']}/${song['visibility']}');
        print('     Auteur: ${song['authors']}');
        print('     ID: ${song['id']}');
        print('');
      }

      // Analyser les filtres actuels
      print('🔍 ANALYSE DES FILTRES ACTUELS:');
      final publishedCount = statusCounts['published'] ?? 0;
      final publicCount = visibilityCounts['public'] ?? 0;
      final membersOnlyCount = visibilityCounts['members_only'] ?? 0;
      
      print('  • Chants avec status "published": $publishedCount');
      print('  • Chants avec visibility "public": $publicCount');
      print('  • Chants avec visibility "members_only": $membersOnlyCount');
      print('  • Total visible avec filtres actuels: ${_calculateVisibleSongs(songsSummary)}');
      
    } catch (e) {
      print('❌ Erreur lors du debug: $e');
    }
  }

  /// Calcule combien de chants seraient visibles avec les filtres actuels
  static int _calculateVisibleSongs(List<Map<String, dynamic>> songs) {
    return songs.where((song) => 
      song['status'] == 'published' && 
      (song['visibility'] == 'public' || song['visibility'] == 'members_only')
    ).length;
  }

  /// Teste différentes requêtes pour comprendre les problèmes
  static Future<void> testQueries() async {
    print('🧪 === TEST DES REQUÊTES ===');
    
    try {
      // Test 1: Tous les chants
      final allSongs = await _firestore.collection(_songsCollection).get();
      print('Test 1 - Tous les chants: ${allSongs.docs.length}');

      // Test 2: Chants publiés seulement
      final publishedSongs = await _firestore.collection(_songsCollection)
          .where('status', isEqualTo: 'published')
          .get();
      print('Test 2 - Chants publiés: ${publishedSongs.docs.length}');

      // Test 3: Chants avec bonne visibilité
      final visibleSongs = await _firestore.collection(_songsCollection)
          .where('visibility', whereIn: ['public', 'members_only'])
          .get();
      print('Test 3 - Chants visibles: ${visibleSongs.docs.length}');

      // Test 4: Combinaison (comme dans le code actuel)
      final filteredSongs = await _firestore.collection(_songsCollection)
          .where('status', isEqualTo: 'published')
          .where('visibility', whereIn: ['public', 'members_only'])
          .get();
      print('Test 4 - Chants filtrés (actuel): ${filteredSongs.docs.length}');

      // Test 5: Chants en draft
      final draftSongs = await _firestore.collection(_songsCollection)
          .where('status', isEqualTo: 'draft')
          .get();
      print('Test 5 - Chants en draft: ${draftSongs.docs.length}');

    } catch (e) {
      print('❌ Erreur lors des tests: $e');
    }
  }

  /// Corrige le statut des chants importés
  static Future<void> fixImportedSongsStatus() async {
    print('🔧 === CORRECTION DES STATUTS ===');
    
    try {
      // Trouver les chants avec statut 'draft' ou autres
      final draftSongs = await _firestore.collection(_songsCollection)
          .where('status', isEqualTo: 'draft')
          .get();
      
      print('📝 Chants en draft trouvés: ${draftSongs.docs.length}');
      
      if (draftSongs.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (var doc in draftSongs.docs) {
          batch.update(doc.reference, {
            'status': 'published',
            'visibility': 'members_only',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        print('✅ ${draftSongs.docs.length} chants mis à jour vers "published/members_only"');
      }

      // Vérifier les chants sans visibilité définie
      final noVisibilitySongs = await _firestore.collection(_songsCollection)
          .where('visibility', isEqualTo: null)
          .get();
          
      if (noVisibilitySongs.docs.isNotEmpty) {
        final batch2 = _firestore.batch();
        
        for (var doc in noVisibilitySongs.docs) {
          batch2.update(doc.reference, {
            'visibility': 'members_only',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch2.commit();
        print('✅ ${noVisibilitySongs.docs.length} chants sans visibilité corrigés');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la correction: $e');
    }
  }
}
