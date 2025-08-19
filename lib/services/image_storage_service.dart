import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'firebase_storage_test.dart';

class ImageStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const Uuid _uuid = Uuid();

  /// Upload une image vers Firebase Storage
  /// Returns l'URL de téléchargement de l'image uploadée
  static Future<String?> uploadImage(
    Uint8List imageBytes, {
    String? customPath,
    String? fileName,
  }) async {
    try {
      print('🚀 Début upload image - Taille: ${imageBytes.length} bytes');
      
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Erreur: Utilisateur non connecté');
        throw Exception('Utilisateur non connecté');
      }
      
      print('✅ Utilisateur connecté: ${user.uid}');

      // Générer un nom de fichier unique si non fourni
      final actualFileName = fileName ?? '${_uuid.v4()}.jpg';
      
      // Construire le chemin de stockage
      final storagePath = customPath ?? 'page_components/images/${user.uid}/$actualFileName';
      print('📁 Chemin de stockage: $storagePath');
      
      final storageRef = _storage.ref().child(storagePath);

      // Metadata pour optimiser le stockage
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('⬆️ Début upload vers Firebase Storage...');
      
      // Uploader l'image
      final uploadTask = storageRef.putData(imageBytes, metadata);
      
      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      print('✅ Upload terminé, récupération de l\'URL...');
      
      // Obtenir l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('🎉 Upload réussi! URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Erreur détaillée lors de l\'upload de l\'image: $e');
      print('📋 Stack trace: ${StackTrace.current}');
      
      // Lancer un diagnostic automatique en cas d'erreur
      print('\n🔍 Lancement du diagnostic Firebase Storage...');
      FirebaseStorageTest.printStorageDebugInfo();
      
      return null;
    }
  }

  /// Supprimer une image du storage via son URL
  static Future<bool> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }

  /// Obtenir les métadonnées d'une image
  static Future<FullMetadata?> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('Erreur lors de la récupération des métadonnées: $e');
      return null;
    }
  }

  /// Lister les images d'un utilisateur
  static Future<List<String>> listUserImages([String? userId]) async {
    try {
      final user = _auth.currentUser;
      if (user == null && userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final actualUserId = userId ?? user!.uid;
      final listRef = _storage.ref().child('page_components/images/$actualUserId');
      
      final listResult = await listRef.listAll();
      final urls = <String>[];
      
      for (final item in listResult.items) {
        try {
          final url = await item.getDownloadURL();
          urls.add(url);
        } catch (e) {
          print('Erreur lors de la récupération de l\'URL pour ${item.name}: $e');
        }
      }
      
      return urls;
    } catch (e) {
      print('Erreur lors de la liste des images: $e');
      return [];
    }
  }

  /// Obtenir la taille d'un fichier image
  static Future<int?> getImageSize(String imageUrl) async {
    try {
      final metadata = await getImageMetadata(imageUrl);
      return metadata?.size;
    } catch (e) {
      print('Erreur lors de la récupération de la taille: $e');
      return null;
    }
  }

  /// Valider qu'une URL est une image Firebase Storage valide
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
           url.contains('storage.googleapis.com');
  }

  /// Nettoyer les images non utilisées (à appeler périodiquement)
  static Future<void> cleanupUnusedImages(List<String> usedUrls) async {
    try {
      final allUserImages = await listUserImages();
      final unusedImages = allUserImages.where((url) => !usedUrls.contains(url));
      
      for (final unusedUrl in unusedImages) {
        await deleteImageByUrl(unusedUrl);
        print('Image inutilisée supprimée: $unusedUrl');
      }
    } catch (e) {
      print('Erreur lors du nettoyage des images: $e');
    }
  }
}