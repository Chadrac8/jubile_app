import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/youtube_playlist_model.dart';

/// Service pour gérer les playlists YouTube de William Marrion Branham
class YouTubePlaylistService {
  static const String collectionName = 'youtube_playlists';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ajoute une nouvelle playlist
  static Future<String?> addPlaylist(YouTubePlaylist playlist) async {
    try {
      // Extraire l'ID de playlist depuis l'URL
      final playlistId = YouTubePlaylist.extractPlaylistId(playlist.playlistUrl);
      
      final playlistWithId = playlist.copyWith(
        playlistId: playlistId,
        updatedAt: DateTime.now());

      // Valider les données
      final errors = playlistWithId.validate();
      if (errors.isNotEmpty) {
        throw Exception('Validation échouée: ${errors.join(', ')}');
      }

      final docRef = await _firestore
          .collection(collectionName)
          .add(playlistWithId.toFirestore());

      print('✅ Playlist ajoutée avec l\'ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la playlist: $e');
      return null;
    }
  }

  /// Met à jour une playlist existante
  static Future<bool> updatePlaylist(String id, YouTubePlaylist playlist) async {
    try {
      // Extraire l'ID de playlist depuis l'URL
      final playlistId = YouTubePlaylist.extractPlaylistId(playlist.playlistUrl);
      
      final playlistWithId = playlist.copyWith(
        id: id,
        playlistId: playlistId,
        updatedAt: DateTime.now());

      // Valider les données
      final errors = playlistWithId.validate();
      if (errors.isNotEmpty) {
        throw Exception('Validation échouée: ${errors.join(', ')}');
      }

      await _firestore
          .collection(collectionName)
          .doc(id)
          .update(playlistWithId.toFirestore());

      print('✅ Playlist mise à jour: $id');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la playlist: $e');
      return false;
    }
  }

  /// Supprime une playlist
  static Future<bool> deletePlaylist(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
      print('✅ Playlist supprimée: $id');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression de la playlist: $e');
      return false;
    }
  }

  /// Récupère toutes les playlists
  static Future<List<YouTubePlaylist>> getAllPlaylists() async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => YouTubePlaylist.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des playlists: $e');
      return [];
    }
  }

  /// Récupère les playlists actives seulement
  static Future<List<YouTubePlaylist>> getActivePlaylists() async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => YouTubePlaylist.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des playlists actives: $e');
      return [];
    }
  }

  /// Stream des playlists actives
  static Stream<List<YouTubePlaylist>> getActivePlaylistsStream() {
    return _firestore
        .collection(collectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => YouTubePlaylist.fromFirestore(doc))
            .toList());
  }

  /// Stream de toutes les playlists (pour l'admin)
  static Stream<List<YouTubePlaylist>> getAllPlaylistsStream() {
    return _firestore
        .collection(collectionName)
        .orderBy('displayOrder')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => YouTubePlaylist.fromFirestore(doc))
            .toList());
  }

  /// Récupère une playlist par son ID
  static Future<YouTubePlaylist?> getPlaylistById(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return YouTubePlaylist.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération de la playlist $id: $e');
      return null;
    }
  }

  /// Active/désactive une playlist
  static Future<bool> togglePlaylistStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(collectionName).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ Statut de la playlist mis à jour: $id -> $isActive');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  /// Recherche dans les playlists
  static Future<List<YouTubePlaylist>> searchPlaylists(String query) async {
    try {
      final allPlaylists = await getAllPlaylists();
      final searchQuery = query.toLowerCase();
      
      return allPlaylists.where((playlist) {
        return playlist.title.toLowerCase().contains(searchQuery) ||
               playlist.description.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('❌ Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// Valide une URL de playlist YouTube
  static Future<bool> validatePlaylistUrl(String url) async {
    try {
      if (!YouTubePlaylist.isValidYouTubePlaylistUrl(url)) {
        return false;
      }

      final playlistId = YouTubePlaylist.extractPlaylistId(url);
      return playlistId.isNotEmpty;
    } catch (e) {
      print('❌ Erreur lors de la validation de l\'URL: $e');
      return false;
    }
  }

  /// Crée des données de démonstration
  static Future<void> createDemoData() async {
    try {
      print('🎥 Création de données de démonstration pour les playlists YouTube...');
      
      final demoPlaylists = [
        YouTubePlaylist(
          id: '',
          title: 'Prédications Fondamentales',
          description: 'Collection des prédications fondamentales de William Marrion Branham',
          playlistId: 'PLrAVYxQgJ_CW0GCZjdX7lVOy2T0xH_z8c', // Exemple d'ID
          playlistUrl: 'https://www.youtube.com/playlist?list=PLrAVYxQgJ_CW0GCZjdX7lVOy2T0xH_z8c',
          thumbnailUrl: '',
          isActive: true,
          displayOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now()),
        YouTubePlaylist(
          id: '',
          title: 'Les Sept Ages de l\'Église',
          description: 'Série complète sur les Sept Ages de l\'Église par William Marrion Branham',
          playlistId: 'PLrAVYxQgJ_CXjNWg8H3vKdV7xD_F2mY9c', // Exemple d'ID
          playlistUrl: 'https://www.youtube.com/playlist?list=PLrAVYxQgJ_CXjNWg8H3vKdV7xD_F2mY9c',
          thumbnailUrl: '',
          isActive: true,
          displayOrder: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now()),
      ];

      for (final playlist in demoPlaylists) {
        await addPlaylist(playlist);
      }

      print('✅ Données de démonstration créées avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création des données de démonstration: $e');
    }
  }
}
