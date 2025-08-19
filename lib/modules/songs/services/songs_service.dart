import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/services/base_firebase_service.dart';
import '../models/song.dart';
import '../models/song_category.dart';
import '../models/song_playlist.dart';

/// Service de gestion des chants
class SongsService extends BaseFirebaseService<Song> {
  @override
  String get collectionName => 'songs';

  /// Service pour les catégories de chants
  final SongCategoriesService _categoriesService = SongCategoriesService();
  
  /// Service pour les playlists de chants
  final SongPlaylistsService _playlistsService = SongPlaylistsService();

  /// Getters pour accéder aux sous-services
  SongCategoriesService get categories => _categoriesService;
  SongPlaylistsService get playlists => _playlistsService;

  @override
  Song fromFirestore(DocumentSnapshot doc) {
    return Song.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(Song model) {
    return model.toMap();
  }

  /// Initialiser le service
  Future<void> initialize() async {
    await _categoriesService.initialize();
    await _playlistsService.initialize();
  }

  /// Libérer les ressources
  Future<void> dispose() async {
    // Pas de ressources spécifiques à libérer pour l'instant
  }

  /// Rechercher des chants par texte
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return await getAll();

    try {
      final queryLower = query.toLowerCase();
      
      // Recherche dans le titre
      final titleResults = await collection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      
      // Recherche dans l'auteur
      final authorResults = await collection
          .where('author', isGreaterThanOrEqualTo: query)
          .where('author', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Combiner les résultats et éliminer les doublons
      final Set<String> seenIds = {};
      final List<Song> results = [];

      for (final doc in [...titleResults.docs, ...authorResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          final song = fromFirestore(doc);
          
          // Filtrage côté client pour une recherche plus précise
          if (song.searchText.contains(queryLower)) {
            results.add(song);
          }
        }
      }

      // Trier par pertinence
      results.sort((a, b) {
        final aTitle = a.title.toLowerCase();
        final bTitle = b.title.toLowerCase();
        
        // Prioriser les correspondances exactes dans le titre
        if (aTitle.startsWith(queryLower) && !bTitle.startsWith(queryLower)) {
          return -1;
        }
        if (!aTitle.startsWith(queryLower) && bTitle.startsWith(queryLower)) {
          return 1;
        }
        
        // Ensuite par ordre alphabétique
        return aTitle.compareTo(bTitle);
      });

      return results;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Obtenir les chants par catégorie
  Future<List<Song>> getSongsByCategory(String categoryName) async {
    try {
      final querySnapshot = await collection
          .where('categories', arrayContains: categoryName)
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération par catégorie: $e');
    }
  }

  /// Obtenir les chants favoris d'un utilisateur
  Future<List<Song>> getFavoriteSongs(String userId) async {
    try {
      final querySnapshot = await collection
          .where('favorites', arrayContains: userId)
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des favoris: $e');
    }
  }

  /// Obtenir les chants les plus populaires
  Future<List<Song>> getPopularSongs({int limit = 20}) async {
    try {
      final querySnapshot = await collection
          .orderBy('views', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des chants populaires: $e');
    }
  }

  /// Obtenir les chants récents
  Future<List<Song>> getRecentSongs({int limit = 20}) async {
    try {
      final querySnapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des chants récents: $e');
    }
  }

  /// Obtenir les chants en attente d'approbation
  Future<List<Song>> getPendingSongs() async {
    try {
      final querySnapshot = await collection
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des chants en attente: $e');
    }
  }

  /// Ajouter/retirer un chant des favoris
  Future<void> toggleFavorite(String songId, String userId) async {
    try {
      final song = await getById(songId);
      if (song == null) throw Exception('Chant non trouvé');

      final updatedFavorites = List<String>.from(song.favorites);
      
      if (updatedFavorites.contains(userId)) {
        updatedFavorites.remove(userId);
      } else {
        updatedFavorites.add(userId);
      }

      await update(songId, song.copyWith(
        favorites: updatedFavorites,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des favoris: $e');
    }
  }

  /// Incrémenter le nombre de vues d'un chant
  Future<void> incrementViews(String songId) async {
    try {
      final song = await getById(songId);
      if (song == null) return;

      await update(songId, song.copyWith(
        views: song.views + 1,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      // Ne pas bloquer l'affichage si l'incrémentation échoue
      print('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  /// Approuver un chant
  Future<void> approveSong(String songId) async {
    try {
      final song = await getById(songId);
      if (song == null) throw Exception('Chant non trouvé');

      await update(songId, song.copyWith(
        isApproved: true,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('Erreur lors de l\'approbation: $e');
    }
  }

  /// Rejeter un chant
  Future<void> rejectSong(String songId) async {
    try {
      await delete(songId);
    } catch (e) {
      throw Exception('Erreur lors du rejet: $e');
    }
  }

  /// Obtenir les statistiques des chants
  Future<Map<String, int>> getStatistics() async {
    try {
      final allSongs = await collection.get();
      final approvedSongs = await collection
          .where('isApproved', isEqualTo: true)
          .get();
      final pendingSongs = await collection
          .where('isApproved', isEqualTo: false)
          .get();

      return {
        'total': allSongs.docs.length,
        'approved': approvedSongs.docs.length,
        'pending': pendingSongs.docs.length,
      };
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}

/// Service de gestion des catégories de chants
class SongCategoriesService extends BaseFirebaseService<SongCategory> {
  @override
  String get collectionName => 'song_categories';

  @override
  SongCategory fromFirestore(DocumentSnapshot doc) {
    return SongCategory.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(SongCategory model) {
    return model.toMap();
  }

  /// Initialiser le service avec les catégories par défaut
  Future<void> initialize() async {
    try {
      final existingCategories = await getAll();
      
      if (existingCategories.isEmpty) {
        // Créer les catégories par défaut
        for (final category in DefaultSongCategories.defaultCategories) {
          await create(category);
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des catégories: $e');
    }
  }

  /// Obtenir les catégories actives triées
  Future<List<SongCategory>> getActiveCategories() async {
    try {
      final querySnapshot = await collection
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }
}

/// Service de gestion des playlists de chants
class SongPlaylistsService extends BaseFirebaseService<SongPlaylist> {
  @override
  String get collectionName => 'song_playlists';

  @override
  SongPlaylist fromFirestore(DocumentSnapshot doc) {
    return SongPlaylist.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Map<String, dynamic> toFirestore(SongPlaylist model) {
    return model.toMap();
  }

  /// Initialiser le service
  Future<void> initialize() async {
    // Pas d'initialisation spécifique pour l'instant
  }

  /// Obtenir les playlists d'un utilisateur
  Future<List<SongPlaylist>> getUserPlaylists(String userId) async {
    try {
      final createdQuery = collection.where('createdBy', isEqualTo: userId);
      final collaboratorQuery = collection.where('collaborators', arrayContains: userId);
      
      final createdSnapshot = await createdQuery.get();
      final collaboratorSnapshot = await collaboratorQuery.get();

      final Set<String> seenIds = {};
      final List<SongPlaylist> playlists = [];

      for (final doc in [...createdSnapshot.docs, ...collaboratorSnapshot.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          playlists.add(fromFirestore(doc));
        }
      }

      playlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return playlists;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des playlists: $e');
    }
  }

  /// Obtenir les playlists publiques
  Future<List<SongPlaylist>> getPublicPlaylists() async {
    try {
      final querySnapshot = await collection
          .where('isPublic', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des playlists publiques: $e');
    }
  }

  /// Obtenir les playlists officielles
  Future<List<SongPlaylist>> getOfficialPlaylists() async {
    try {
      final querySnapshot = await collection
          .where('isOfficial', isEqualTo: true)
          .orderBy('title')
          .get();
      
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des playlists officielles: $e');
    }
  }
}