import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/thematic_passage_model.dart';
import '../bible_service.dart';
import 'predefined_themes.dart';

/// Service pour gérer les passages thématiques bibliques
class ThematicPassageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _themesCollection = 'biblical_themes';
  static const String _passagesCollection = 'thematic_passages';

  /// Vérifie la connectivité Firebase
  static Future<bool> checkFirebaseConnection() async {
    try {
      await _firestore.doc('test/connection').get();
      return true;
    } catch (e) {
      print('Erreur de connexion Firebase: $e');
      return false;
    }
  }

  /// S'assure qu'un utilisateur est authentifié (connexion anonyme si nécessaire)
  static Future<User> _ensureAuthenticated() async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      try {
        print('Tentative de connexion anonyme automatique...');
        final userCredential = await _auth.signInAnonymously();
        user = userCredential.user;
        if (user != null) {
          print('Connexion anonyme réussie: ${user.uid}');
        }
      } catch (e) {
        print('Échec de la connexion anonyme: $e');
        throw Exception('Connexion requise. L\'authentification anonyme n\'est pas activée sur ce projet Firebase.');
      }
    }
    
    if (user == null) {
      throw Exception('Impossible de se connecter. Veuillez contacter l\'administrateur.');
    }
    
    return user;
  }

  /// Récupère tous les thèmes publics
  static Stream<List<BiblicalTheme>> getPublicThemes() {
    try {
      return _firestore
          .collection(_themesCollection)
          .where('isPublic', isEqualTo: true)
          .orderBy('name')
          .snapshots()
          .asyncMap((snapshot) async {
        try {
          // Si aucun thème n'existe, initialiser les thèmes par défaut
          if (snapshot.docs.isEmpty) {
            await _ensureDefaultThemesExist();
            // Récupérer à nouveau après l'initialisation
            final newSnapshot = await _firestore
                .collection(_themesCollection)
                .where('isPublic', isEqualTo: true)
                .orderBy('name')
                .get();
            
            if (newSnapshot.docs.isEmpty) {
              return <BiblicalTheme>[];
            }
            
            List<BiblicalTheme> themes = [];
            for (var doc in newSnapshot.docs) {
              try {
                final data = doc.data();
                final passageIds = List<String>.from(data['passageIds'] ?? []);
                
                // Récupérer les passages pour ce thème
                List<ThematicPassage> passages = [];
                if (passageIds.isNotEmpty) {
                  final passagesSnapshot = await _firestore
                      .collection(_passagesCollection)
                      .where(FieldPath.documentId, whereIn: passageIds)
                      .get();
                  
                  passages = passagesSnapshot.docs
                      .map((doc) => ThematicPassage.fromJson(doc.data()))
                      .toList();
                }
                
                themes.add(BiblicalTheme.fromJson(data, passages));
              } catch (e) {
                print('Erreur lors du traitement du thème ${doc.id}: $e');
                // Continue avec le thème suivant
              }
            }
            return themes;
          }
          
          List<BiblicalTheme> themes = [];
          
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final passageIds = List<String>.from(data['passageIds'] ?? []);
              
              // Récupérer les passages pour ce thème
              List<ThematicPassage> passages = [];
              if (passageIds.isNotEmpty) {
                final passagesSnapshot = await _firestore
                    .collection(_passagesCollection)
                    .where(FieldPath.documentId, whereIn: passageIds)
                    .get();
                
                passages = passagesSnapshot.docs
                    .map((doc) => ThematicPassage.fromJson(doc.data()))
                    .toList();
              }
              
              themes.add(BiblicalTheme.fromJson(data, passages));
            } catch (e) {
              print('Erreur lors du traitement du thème ${doc.id}: $e');
              // Continue avec le thème suivant
            }
          }
          
          return themes;
        } catch (e) {
          print('Erreur lors du traitement des thèmes: $e');
          throw Exception('Erreur lors du chargement des thèmes: $e');
        }
      }).handleError((error) {
        print('Erreur dans le stream des thèmes publics: $error');
        throw Exception('Connexion aux données impossible: $error');
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation du stream: $e');
      return Stream.error('Erreur de configuration: $e');
    }
  }

  /// Vérifie et s'assure que les thèmes par défaut existent
  static Future<void> _ensureDefaultThemesExist() async {
    try {
      print('Initialisation automatique des thèmes par défaut...');
      await initializeDefaultThemes();
      print('Thèmes par défaut initialisés avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation des thèmes par défaut: $e');
      // Ne pas lancer d'erreur pour ne pas bloquer l'interface
    }
  }

  /// Récupère les thèmes créés par l'utilisateur actuel
  static Stream<List<BiblicalTheme>> getUserThemes() {
    final user = _auth.currentUser;
    if (user == null) {
      // Retourner une liste vide sans essayer d'authentification automatique
      print('Aucun utilisateur connecté - retour d\'une liste vide');
      return Stream.value(<BiblicalTheme>[]);
    }

    try {
      return _firestore
          .collection(_themesCollection)
          .where('createdBy', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        try {
          List<BiblicalTheme> themes = [];
          
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final passageIds = List<String>.from(data['passageIds'] ?? []);
              
              // Récupérer les passages pour ce thème
              List<ThematicPassage> passages = [];
              if (passageIds.isNotEmpty) {
                final passagesSnapshot = await _firestore
                    .collection(_passagesCollection)
                    .where(FieldPath.documentId, whereIn: passageIds)
                    .get();
                
                passages = passagesSnapshot.docs
                    .map((doc) => ThematicPassage.fromJson(doc.data()))
                    .toList();
              }
              
              themes.add(BiblicalTheme.fromJson(data, passages));
            } catch (e) {
              print('Erreur lors du traitement du thème utilisateur ${doc.id}: $e');
              // Continue avec le thème suivant
            }
          }
          
          return themes;
        } catch (e) {
          print('Erreur lors du traitement des thèmes utilisateur: $e');
          throw Exception('Erreur lors du chargement de vos thèmes: $e');
        }
      }).handleError((error) {
        print('Erreur dans le stream des thèmes utilisateur: $error');
        throw Exception('Connexion aux données impossible: $error');
      });
    } catch (e) {
      print('Erreur lors de l\'initialisation du stream utilisateur: $e');
      return Stream.error('Erreur de configuration: $e');
    }
  }

  /// Crée un nouveau thème
  static Future<String> createTheme({
    required String name,
    required String description,
    required Color color,
    required IconData icon,
    bool isPublic = false,
  }) async {
    final user = await _ensureAuthenticated();

    final themeId = _firestore.collection(_themesCollection).doc().id;
    
    final theme = BiblicalTheme(
      id: themeId,
      name: name,
      description: description,
      color: color,
      icon: icon,
      passages: [],
      createdAt: DateTime.now(),
      createdBy: user.uid,
      createdByName: user.displayName ?? 'Utilisateur',
      isPublic: isPublic);

    await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .set(theme.toJson());

    return themeId;
  }

  /// Ajoute un passage à un thème
  static Future<void> addPassageToTheme({
    required String themeId,
    required String reference,
    required String book,
    required int chapter,
    required int startVerse,
    int? endVerse,
    required String description,
    List<String> tags = const [],
  }) async {
    final user = await _ensureAuthenticated();

    // Récupérer le texte du passage depuis la Bible
    final bibleService = BibleService();
    await bibleService.loadBible();
    
    String passageText = '';
    try {
      if (endVerse != null && endVerse > startVerse) {
        // Plusieurs versets
        List<String> verseTexts = [];
        for (int v = startVerse; v <= endVerse; v++) {
          final verse = bibleService.getVerse(book, chapter, v);
          if (verse != null) {
            verseTexts.add(verse.text);
          }
        }
        passageText = verseTexts.join(' ');
      } else {
        // Un seul verset
        final verse = bibleService.getVerse(book, chapter, startVerse);
        passageText = verse?.text ?? 'Texte non disponible';
      }
    } catch (e) {
      passageText = 'Texte non disponible';
    }

    final passageId = _firestore.collection(_passagesCollection).doc().id;
    
    final passage = ThematicPassage(
      id: passageId,
      reference: reference,
      book: book,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      text: passageText,
      theme: themeId,
      description: description,
      tags: tags,
      createdAt: DateTime.now(),
      createdBy: user.uid,
      createdByName: user.displayName ?? 'Utilisateur');

    // Sauvegarder le passage
    await _firestore
        .collection(_passagesCollection)
        .doc(passageId)
        .set(passage.toJson());

    // Mettre à jour la liste des passages du thème
    await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .update({
      'passageIds': FieldValue.arrayUnion([passageId]),
    });
  }

  /// Supprime un passage d'un thème
  static Future<void> removePassageFromTheme(String themeId, String passageId) async {
    // Supprimer le passage
    await _firestore
        .collection(_passagesCollection)
        .doc(passageId)
        .delete();

    // Mettre à jour la liste des passages du thème
    await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .update({
      'passageIds': FieldValue.arrayRemove([passageId]),
    });
  }

  /// Met à jour un thème existant
  static Future<void> updateTheme({
    required String themeId,
    required String name,
    required String description,
    required Color color,
    required IconData icon,
    bool isPublic = false,
  }) async {
    final user = await _ensureAuthenticated();

    // Vérifier que le thème existe et que l'utilisateur a les permissions
    final themeDoc = await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .get();

    if (!themeDoc.exists) throw Exception('Thème non trouvé');

    final themeData = themeDoc.data()!;
    if (themeData['createdBy'] != user.uid) {
      throw Exception('Vous n\'avez pas les permissions pour modifier ce thème');
    }

    // Mettre à jour les données du thème
    await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .update({
      'name': name,
      'description': description,
      'color': color.value,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'isPublic': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprime un thème complet
  static Future<void> deleteTheme(String themeId) async {
    final user = await _ensureAuthenticated();

    // Récupérer le thème pour vérifier les permissions
    final themeDoc = await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .get();

    if (!themeDoc.exists) throw Exception('Thème non trouvé');

    final themeData = themeDoc.data()!;
    if (themeData['createdBy'] != user.uid) {
      throw Exception('Vous n\'avez pas les permissions pour supprimer ce thème');
    }

    // Supprimer tous les passages du thème
    final passageIds = List<String>.from(themeData['passageIds'] ?? []);
    for (String passageId in passageIds) {
      await _firestore
          .collection(_passagesCollection)
          .doc(passageId)
          .delete();
    }

    // Supprimer le thème
    await _firestore
        .collection(_themesCollection)
        .doc(themeId)
        .delete();
  }

  /// Initialise les thèmes prédéfinis si aucun thème public n'existe
  static Future<void> initializeDefaultThemes() async {
    final existingThemes = await _firestore
        .collection(_themesCollection)
        .where('isPublic', isEqualTo: true)
        .limit(1)
        .get();

    if (existingThemes.docs.isNotEmpty) return; // Des thèmes existent déjà

    final defaultThemes = PredefinedThemes.getDefaultThemes();
    final bibleService = BibleService();
    await bibleService.loadBible();

    for (var themeData in defaultThemes) {
      final themeId = _firestore.collection(_themesCollection).doc().id;
      
      // Créer les passages pour ce thème
      List<String> passageIds = [];
      for (var passageData in themeData['passages']) {
        final passageId = await _createPredefinedPassage(
          passageData,
          themeId,
          bibleService);
        passageIds.add(passageId);
      }

      // Créer le thème
      await _firestore
          .collection(_themesCollection)
          .doc(themeId)
          .set({
        'id': themeId,
        'name': themeData['name'],
        'description': themeData['description'],
        'color': themeData['color'],
        'iconCodePoint': themeData['iconCodePoint'],
        'iconFontFamily': themeData['iconFontFamily'],
        'passageIds': passageIds,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'system',
        'createdByName': 'ChurchFlow',
        'isPublic': true,
      });
    }
  }

  /// Crée un passage prédéfini
  static Future<String> _createPredefinedPassage(
    Map<String, dynamic> passageData,
    String themeId,
    BibleService bibleService) async {
    final passageId = _firestore.collection(_passagesCollection).doc().id;
    final reference = passageData['reference'] as String;
    
    // Parser la référence (ex: "Jean 3:16" ou "Romains 8:38-39")
    final parts = reference.split(' ');
    if (parts.length < 2) return passageId;
    
    final book = parts.sublist(0, parts.length - 1).join(' ');
    final chapterVerse = parts.last;
    final chapterVerseparts = chapterVerse.split(':');
    if (chapterVerseparts.length != 2) return passageId;
    
    final chapter = int.tryParse(chapterVerseparts[0]);
    if (chapter == null) return passageId;
    
    final versePart = chapterVerseparts[1];
    int startVerse, endVerse;
    
    if (versePart.contains('-')) {
      final verseRange = versePart.split('-');
      startVerse = int.tryParse(verseRange[0]) ?? 1;
      endVerse = int.tryParse(verseRange[1]) ?? startVerse;
    } else {
      startVerse = int.tryParse(versePart) ?? 1;
      endVerse = startVerse;
    }

    // Récupérer le texte
    String text = 'Texte non disponible';
    try {
      if (endVerse > startVerse) {
        // Plusieurs versets
        List<String> verseTexts = [];
        for (int v = startVerse; v <= endVerse; v++) {
          final verse = bibleService.getVerse(book, chapter, v);
          if (verse != null) {
            verseTexts.add(verse.text);
          }
        }
        text = verseTexts.join(' ');
      } else {
        // Un seul verset
        final verse = bibleService.getVerse(book, chapter, startVerse);
        text = verse?.text ?? 'Texte non disponible';
      }
    } catch (e) {
      // Garde le texte par défaut
    }

    await _firestore
        .collection(_passagesCollection)
        .doc(passageId)
        .set({
      'id': passageId,
      'reference': reference,
      'book': book,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse != startVerse ? endVerse : null,
      'text': text,
      'theme': themeId,
      'description': passageData['description'],
      'tags': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': 'system',
      'createdByName': 'ChurchFlow',
    });

    return passageId;
  }
}
