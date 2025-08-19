import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _favoriteSongsKey = 'favorite_songs';
  static const String _userIdKey = 'current_user_id';
  
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // Sauvegarde des favoris
  static Future<void> saveFavoriteSongs(String userId, List<String> songIds) async {
    await init();
    await _prefs!.setString('${_favoriteSongsKey}_$userId', json.encode(songIds));
  }
  
  // Récupération des favoris
  static Future<List<String>> getFavoriteSongs(String userId) async {
    await init();
    final favoritesJson = _prefs!.getString('${_favoriteSongsKey}_$userId');
    if (favoritesJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(favoritesJson);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  // Ajouter un favori
  static Future<void> addFavoriteSong(String userId, String songId) async {
    final favorites = await getFavoriteSongs(userId);
    if (!favorites.contains(songId)) {
      favorites.add(songId);
      await saveFavoriteSongs(userId, favorites);
    }
  }
  
  // Supprimer un favori
  static Future<void> removeFavoriteSong(String userId, String songId) async {
    final favorites = await getFavoriteSongs(userId);
    favorites.remove(songId);
    await saveFavoriteSongs(userId, favorites);
  }
  
  // Vérifier si un chant est favori
  static Future<bool> isSongFavorite(String userId, String songId) async {
    final favorites = await getFavoriteSongs(userId);
    return favorites.contains(songId);
  }
  
  // Synchroniser avec le serveur
  static Future<void> syncFavorites(String userId, List<String> serverFavorites) async {
    await saveFavoriteSongs(userId, serverFavorites);
  }
  
  // Nettoyer les données d'un utilisateur
  static Future<void> clearUserData(String userId) async {
    await init();
    await _prefs!.remove('${_favoriteSongsKey}_$userId');
  }
}