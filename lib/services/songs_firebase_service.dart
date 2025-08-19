import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song_model.dart';

/// Service Firebase pour la gestion des chants
class SongsFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _songsCollection = 'songs';
  static const String _setlistsCollection = 'setlists';
  static const String _favoritesCollection = 'user_favorites';

  /// Obtient tous les chants
  static Stream<List<SongModel>> getSongs() {
    return _firestore
        .collection(_songsCollection)
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList());
  }

  /// Obtient les chants publiés pour les membres
  static Stream<List<SongModel>> getPublishedSongs() {
    return _firestore
        .collection(_songsCollection)
        .where('status', isEqualTo: 'published')
        .where('visibility', whereIn: ['public', 'members_only'])
        .orderBy('title')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList());
  }

  /// Obtient les chants populaires (les plus utilisés)
  static Stream<List<SongModel>> getPopularSongs({int limit = 20}) {
    return _firestore
        .collection(_songsCollection)
        .where('status', isEqualTo: 'published')
        .where('visibility', whereIn: ['public', 'members_only'])
        .orderBy('usageCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList());
  }

  /// Obtient les chants récents
  static Stream<List<SongModel>> getRecentSongs({int limit = 20}) {
    return _firestore
        .collection(_songsCollection)
        .where('status', isEqualTo: 'published')
        .where('visibility', whereIn: ['public', 'members_only'])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .toList());
  }

  /// Recherche des chants
  static Stream<List<SongModel>> searchSongs(String query) {
    if (query.isEmpty) return getPublishedSongs();
    
    return _firestore
        .collection(_songsCollection)
        .where('status', isEqualTo: 'published')
        .where('visibility', whereIn: ['public', 'members_only'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SongModel.fromFirestore(doc))
            .where((song) => 
                song.title.toLowerCase().contains(query.toLowerCase()) ||
                song.authors.toLowerCase().contains(query.toLowerCase()) ||
                song.lyrics.toLowerCase().contains(query.toLowerCase()) ||
                song.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
            .toList());
  }

  /// Obtient un chant par son ID
  static Future<SongModel?> getSong(String id) async {
    try {
      final doc = await _firestore.collection(_songsCollection).doc(id).get();
      return doc.exists ? SongModel.fromFirestore(doc) : null;
    } catch (e) {
      print('Erreur lors de la récupération du chant: $e');
      return null;
    }
  }

  /// Crée un nouveau chant
  static Future<String?> createSong(SongModel song) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final songData = song.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
      );

      final docRef = await _firestore
          .collection(_songsCollection)
          .add(songData.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du chant: $e');
      return null;
    }
  }

  /// Met à jour un chant
  static Future<bool> updateSong(String id, SongModel song) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final songData = song.copyWith(
        updatedAt: DateTime.now(),
        modifiedBy: user.uid,
      );

      await _firestore
          .collection(_songsCollection)
          .doc(id)
          .update(songData.toFirestore());
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du chant: $e');
      return false;
    }
  }

  /// Supprime un chant
  static Future<bool> deleteSong(String id) async {
    try {
      await _firestore.collection(_songsCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du chant: $e');
      return false;
    }
  }

  /// Incrémente le compteur d'utilisation d'un chant
  static Future<void> incrementSongUsage(String songId) async {
    try {
      final docRef = _firestore.collection(_songsCollection).doc(songId);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (doc.exists) {
          final currentCount = doc.data()?['usageCount'] ?? 0;
          transaction.update(docRef, {
            'usageCount': currentCount + 1,
            'lastUsedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Erreur lors de l\'incrémentation de l\'utilisation: $e');
    }
  }

  /// Obtient les chants favoris d'un utilisateur
  static Stream<List<String>> getUserFavorites() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_favoritesCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            return List<String>.from(data['songIds'] ?? []);
          }
          return <String>[];
        });
  }

  /// Ajoute un chant aux favoris
  static Future<bool> addToFavorites(String songId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection(_favoritesCollection)
          .doc(user.uid)
          .set({
            'songIds': FieldValue.arrayUnion([songId]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  /// Retire un chant des favoris
  static Future<bool> removeFromFavorites(String songId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection(_favoritesCollection)
          .doc(user.uid)
          .update({
            'songIds': FieldValue.arrayRemove([songId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return true;
    } catch (e) {
      print('Erreur lors de la suppression des favoris: $e');
      return false;
    }
  }

  /// Obtient les chants favoris complets
  static Stream<List<SongModel>> getFavoriteSongs() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return getUserFavorites().asyncMap((favoriteIds) async {
      if (favoriteIds.isEmpty) return <SongModel>[];

      final songs = <SongModel>[];
      for (final id in favoriteIds) {
        final song = await getSong(id);
        if (song != null) {
          songs.add(song);
        }
      }
      return songs;
    });
  }

  // === GESTION DES SETLISTS ===

  /// Obtient toutes les setlists
  static Stream<List<SetlistModel>> getSetlists() {
    return _firestore
        .collection(_setlistsCollection)
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SetlistModel.fromFirestore(doc))
            .toList());
  }

  /// Obtient une setlist par son ID
  static Future<SetlistModel?> getSetlist(String id) async {
    try {
      final doc = await _firestore.collection(_setlistsCollection).doc(id).get();
      return doc.exists ? SetlistModel.fromFirestore(doc) : null;
    } catch (e) {
      print('Erreur lors de la récupération de la setlist: $e');
      return null;
    }
  }

  /// Crée une nouvelle setlist
  static Future<String?> createSetlist(SetlistModel setlist) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final setlistData = setlist.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.uid,
      );

      final docRef = await _firestore
          .collection(_setlistsCollection)
          .add(setlistData.toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la setlist: $e');
      return null;
    }
  }

  /// Met à jour une setlist
  static Future<bool> updateSetlist(String id, SetlistModel setlist) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final setlistData = setlist.copyWith(
        updatedAt: DateTime.now(),
        modifiedBy: user.uid,
      );

      await _firestore
          .collection(_setlistsCollection)
          .doc(id)
          .update(setlistData.toFirestore());
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la setlist: $e');
      return false;
    }
  }

  /// Supprime une setlist
  static Future<bool> deleteSetlist(String id) async {
    try {
      await _firestore.collection(_setlistsCollection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la setlist: $e');
      return false;
    }
  }

  /// Obtient les chants d'une setlist avec leurs détails complets
  static Future<List<SongModel>> getSetlistSongs(List<String> songIds) async {
    if (songIds.isEmpty) return [];

    final songs = <SongModel>[];
    for (final id in songIds) {
      final song = await getSong(id);
      if (song != null) {
        songs.add(song);
      }
    }
    return songs;
  }

  /// Filtre les chants par critères
  static Stream<List<SongModel>> filterSongs({
    String? style,
    String? key,
    List<String>? tags,
    String? status,
    String? visibility,
  }) {
    Query query = _firestore.collection(_songsCollection);

    if (style != null && style.isNotEmpty) {
      query = query.where('style', isEqualTo: style);
    }

    if (key != null && key.isNotEmpty) {
      query = query.where('originalKey', isEqualTo: key);
    }

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    if (visibility != null && visibility.isNotEmpty) {
      query = query.where('visibility', isEqualTo: visibility);
    }

    return query
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
          var songs = snapshot.docs
              .map((doc) => SongModel.fromFirestore(doc))
              .toList();

          // Filtrer par tags si spécifié
          if (tags != null && tags.isNotEmpty) {
            songs = songs.where((song) => 
                tags.any((tag) => song.tags.contains(tag))
            ).toList();
          }

          return songs;
        });
  }

  /// Obtient tous les chants (pour l'export)
  static Future<List<SongModel>> getAllSongs() async {
    try {
      final snapshot = await _firestore.collection(_songsCollection).get();
      return snapshot.docs
          .map((doc) => SongModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération de tous les chants: $e');
      return [];
    }
  }

  /// Obtient les statistiques des chants
  static Future<Map<String, dynamic>> getSongsStatistics() async {
    try {
      final snapshot = await _firestore.collection(_songsCollection).get();
      final songs = snapshot.docs.map((doc) => SongModel.fromFirestore(doc)).toList();

      final stats = <String, dynamic>{
        'totalSongs': songs.length,
        'publishedSongs': songs.where((s) => s.status == 'published').length,
        'draftSongs': songs.where((s) => s.status == 'draft').length,
        'archivedSongs': songs.where((s) => s.status == 'archived').length,
        'totalUsage': songs.fold<int>(0, (sum, song) => sum + song.usageCount),
        'averageUsage': songs.isNotEmpty 
            ? songs.fold<int>(0, (sum, song) => sum + song.usageCount) / songs.length
            : 0,
        'styleDistribution': _getStyleDistribution(songs),
        'keyDistribution': _getKeyDistribution(songs),
      };

      return stats;
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// Calcule la distribution par style
  static Map<String, int> _getStyleDistribution(List<SongModel> songs) {
    final distribution = <String, int>{};
    for (final song in songs) {
      distribution[song.style] = (distribution[song.style] ?? 0) + 1;
    }
    return distribution;
  }

  /// Calcule la distribution par tonalité
  static Map<String, int> _getKeyDistribution(List<SongModel> songs) {
    final distribution = <String, int>{};
    for (final song in songs) {
      distribution[song.originalKey] = (distribution[song.originalKey] ?? 0) + 1;
    }
    return distribution;
  }
}