import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Service pour gérer l'upload d'images vers Firebase Storage
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload une image vers Firebase Storage
  /// 
  /// [file] - Le fichier image à uploader
  /// [folder] - Le dossier dans lequel uploader (ex: 'resources', 'profiles', etc.)
  /// [fileName] - Nom personnalisé pour le fichier (optionnel)
  /// 
  /// Retourne l'URL de téléchargement de l'image uploadée
  static Future<String?> uploadImage({
    required File file,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Générer un nom de fichier unique si non fourni
      final String finalFileName = fileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      
      // Créer la référence dans Storage
      final Reference ref = _storage.ref().child('$folder/$finalFileName');
      
      // Uploader le fichier
      final UploadTask uploadTask = ref.putFile(file);
      
      // Attendre la fin de l'upload
      final TaskSnapshot snapshot = await uploadTask;
      
      // Obtenir l'URL de téléchargement
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
      
    } catch (e) {
      return null;
    }
  }

  /// Supprimer une image de Firebase Storage
  /// 
  /// [url] - L'URL de l'image à supprimer
  static Future<bool> deleteImage(String url) async {
    try {
      // Extraire le chemin depuis l'URL
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload une image pour les ressources
  static Future<String?> uploadResourceImage(File file, String resourceId) async {
    return await uploadImage(
      file: file,
      folder: 'resources',
      fileName: 'resource_${resourceId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
  }

  /// Upload une image de profil
  static Future<String?> uploadProfileImage(File file, String userId) async {
    return await uploadImage(
      file: file,
      folder: 'profiles',
      fileName: 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
  }
}
