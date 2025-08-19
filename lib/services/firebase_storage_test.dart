import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseStorageTest {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test la connectivité à Firebase Storage
  static Future<Map<String, dynamic>> testStorageConnection() async {
    final result = <String, dynamic>{
      'isAuthenticated': false,
      'canAccessStorage': false,
      'canUpload': false,
      'errors': <String>[],
      'details': <String, dynamic>{},
    };

    try {
      // Test 1: Vérifier l'authentification
      final user = _auth.currentUser;
      if (user == null) {
        result['errors'].add('Utilisateur non connecté');
        return result;
      }
      
      result['isAuthenticated'] = true;
      result['details']['userId'] = user.uid;
      result['details']['isAnonymous'] = user.isAnonymous;
      
      // Test 2: Vérifier l'accès au Storage
      try {
        final testRef = _storage.ref().child('test_connection');
        result['canAccessStorage'] = true;
        result['details']['storageRef'] = testRef.fullPath;
      } catch (e) {
        result['errors'].add('Erreur d\'accès au Storage: $e');
        return result;
      }

      // Test 3: Tenter un mini upload
      try {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]); // 5 bytes de test
        final testRef = _storage.ref().child('test_uploads/${user.uid}/test.bin');
        
        final uploadTask = testRef.putData(testData);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        result['canUpload'] = true;
        result['details']['testUploadUrl'] = downloadUrl;
        
        // Nettoyer le test
        await testRef.delete();
        
      } catch (e) {
        result['errors'].add('Erreur d\'upload: $e');
      }

    } catch (e) {
      result['errors'].add('Erreur générale: $e');
    }

    return result;
  }

  /// Test spécifique pour l'upload d'images
  static Future<Map<String, dynamic>> testImageUpload() async {
    final result = <String, dynamic>{
      'success': false,
      'url': null,
      'error': null,
      'details': <String, dynamic>{},
    };

    try {
      final user = _auth.currentUser;
      if (user == null) {
        result['error'] = 'Utilisateur non connecté';
        return result;
      }

      // Créer une image de test minimale (pixels blancs)
      final testImageData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, // Header JPEG
        // ... données minimales d'une image JPEG
      ]);

      final testRef = _storage.ref().child(
        'test_images/${user.uid}/test_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'test': 'true',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = testRef.putData(testImageData, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      result['success'] = true;
      result['url'] = downloadUrl;
      result['details']['path'] = testRef.fullPath;
      result['details']['size'] = testImageData.length;

      // Nettoyer
      await testRef.delete();

    } catch (e) {
      result['error'] = e.toString();
      result['details']['stackTrace'] = StackTrace.current.toString();
    }

    return result;
  }

  /// Afficher les informations de debug
  static Future<void> printStorageDebugInfo() async {
    print('\n🔧 === DEBUG FIREBASE STORAGE ===');
    
    final connectionTest = await testStorageConnection();
    print('✅ Test de connexion:');
    connectionTest.forEach((key, value) {
      print('   $key: $value');
    });

    print('\n📸 Test d\'upload d\'image:');
    final imageTest = await testImageUpload();
    imageTest.forEach((key, value) {
      print('   $key: $value');
    });

    print('=== FIN DEBUG ===\n');
  }
}