import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';

class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String personsCollection = 'persons';

  /// Migration pour ajouter des UIDs aux personnes existantes qui n'en ont pas
  static Future<void> migratePersonsWithoutUid() async {
    try {
      print('🔄 Début de la migration des personnes sans UID...');
      
      // Récupérer toutes les personnes qui n'ont pas d'UID
      final querySnapshot = await _firestore
          .collection(personsCollection)
          .where('uid', isEqualTo: null)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('✅ Aucune personne à migrer - toutes ont déjà un UID');
        return;
      }

      print('📊 ${querySnapshot.docs.length} personnes à migrer...');
      
      final batch = _firestore.batch();
      int batchCount = 0;
      
      for (final doc in querySnapshot.docs) {
        final person = PersonModel.fromFirestore(doc);
        
        // Ajouter un commentaire dans customFields pour indiquer que cette personne
        // a été créée manuellement (pas liée à un compte Firebase)
        final updatedCustomFields = Map<String, dynamic>.from(person.customFields);
        updatedCustomFields['migrationNote'] = 'Créé manuellement - pas de compte Firebase associé';
        updatedCustomFields['migratedAt'] = FieldValue.serverTimestamp();
        
        // Mettre à jour le document avec une note dans customFields
        batch.update(doc.reference, {
          'customFields': updatedCustomFields,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        batchCount++;
        
        // Exécuter le batch tous les 500 documents
        if (batchCount >= 500) {
          await batch.commit();
          print('📦 Batch de $batchCount documents traité');
          batchCount = 0;
        }
      }
      
      // Exécuter le batch restant
      if (batchCount > 0) {
        await batch.commit();
        print('📦 Batch final de $batchCount documents traité');
      }
      
      print('✅ Migration terminée avec succès');
    } catch (e) {
      print('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  /// Vérifie s'il y a des doublons de personnes avec le même email
  static Future<List<Map<String, dynamic>>> findDuplicateEmails() async {
    try {
      final querySnapshot = await _firestore
          .collection(personsCollection)
          .get();

      final emailMap = <String, List<DocumentSnapshot>>{};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final email = data['email'] as String?;
        
        if (email != null && email.isNotEmpty) {
          if (!emailMap.containsKey(email.toLowerCase())) {
            emailMap[email.toLowerCase()] = [];
          }
          emailMap[email.toLowerCase()]!.add(doc);
        }
      }

      final duplicates = <Map<String, dynamic>>[];
      
      emailMap.forEach((email, docs) {
        if (docs.length > 1) {
          duplicates.add({
            'email': email,
            'count': docs.length,
            'documents': docs.map((doc) => {
              'id': doc.id,
              'data': doc.data(),
            }).toList(),
          });
        }
      });

      return duplicates;
    } catch (e) {
      print('❌ Erreur lors de la recherche de doublons: $e');
      return [];
    }
  }

  /// Résout les doublons en gardant la personne avec UID et supprimant les autres
  static Future<void> resolveDuplicates() async {
    try {
      final duplicates = await findDuplicateEmails();
      
      if (duplicates.isEmpty) {
        print('✅ Aucun doublon détecté');
        return;
      }

      print('🔍 ${duplicates.length} emails en doublon détectés');
      
      for (final duplicate in duplicates) {
        final email = duplicate['email'] as String;
        final documents = duplicate['documents'] as List<dynamic>;
        
        print('📧 Traitement des doublons pour: $email');
        
        // Trouver la personne avec UID (utilisateur connecté)
        DocumentSnapshot? personWithUid;
        final List<DocumentSnapshot> personsWithoutUid = [];
        
        for (final docData in documents) {
          final data = docData['data'] as Map<String, dynamic>;
          if (data['uid'] != null) {
            // Cette personne a un UID, c'est un utilisateur connecté
            if (personWithUid == null) {
              personWithUid = await _firestore
                  .collection(personsCollection)
                  .doc(docData['id'] as String)
                  .get();
            }
          } else {
            // Cette personne n'a pas d'UID, c'est une création manuelle
            final doc = await _firestore
                .collection(personsCollection)
                .doc(docData['id'] as String)
                .get();
            personsWithoutUid.add(doc);
          }
        }

        if (personWithUid != null && personsWithoutUid.isNotEmpty) {
          // Garder la personne avec UID et supprimer les autres
          print('  → Suppression de ${personsWithoutUid.length} doublons manuels');
          
          final batch = _firestore.batch();
          for (final doc in personsWithoutUid) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          
          print('  ✅ Doublons supprimés pour $email');
        } else {
          print('  ⚠️ Situation complexe pour $email - intervention manuelle requise');
        }
      }
      
      print('✅ Résolution des doublons terminée');
    } catch (e) {
      print('❌ Erreur lors de la résolution des doublons: $e');
      rethrow;
    }
  }

  /// Exécute toutes les migrations nécessaires
  static Future<void> runAllMigrations() async {
    print('🚀 Début des migrations...');
    
    try {
      await migratePersonsWithoutUid();
      await resolveDuplicates();
      
      print('🎉 Toutes les migrations sont terminées avec succès');
    } catch (e) {
      print('💥 Erreur lors des migrations: $e');
      rethrow;
    }
  }
}