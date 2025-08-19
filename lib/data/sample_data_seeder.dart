import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/roles_firebase_service.dart';

/// Service pour initialiser les données essentielles de l'application
class SampleDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialiser les données système essentielles
  static Future<void> initializeSystemData() async {
    try {
      print('🔧 Initialisation des données système...');
      
      // Créer les rôles système par défaut uniquement
      await RolesFirebaseService.createDefaultRoles();
      
      print('✅ Données système initialisées avec succès !');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des données système: $e');
      rethrow;
    }
  }
}